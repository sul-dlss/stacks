module ActionController
  module HttpAuthentication
    # Makes it dead easy to do HTTP Bearer authentication.
    #
    # Simple Bearer example:
    #
    #   class PostsController < ApplicationController
    #     BEARER_TOKEN = "secret"
    #
    #     before_action :authenticate, except: [ :index ]
    #
    #     def index
    #       render plain: "Everyone can see me!"
    #     end
    #
    #     def edit
    #       render plain: "I'm only accessible if you know the password"
    #     end
    #
    #     private
    #       def authenticate
    #         authenticate_or_request_with_http_bearer_token do |token, options|
    #           token == TOKEN
    #         end
    #       end
    #   end
    #
    #
    # Here is a more advanced Bearer Token example where only Atom feeds and the XML API is protected by HTTP token authentication,
    # the regular HTML interface is protected by a session approach:
    #
    #   class ApplicationController < ActionController::Base
    #     before_action :set_account, :authenticate
    #
    #     protected
    #       def set_account
    #         @account = Account.find_by(url_name: request.subdomains.first)
    #       end
    #
    #       def authenticate
    #         case request.format
    #         when Mime::XML, Mime::ATOM
    #           if user = authenticate_with_http_bearer_token { |t, o| @account.users.authenticate(t, o) }
    #             @current_user = user
    #           else
    #             request_http_token_authentication
    #           end
    #         else
    #           if session_authenticated?
    #             @current_user = @account.users.find(session[:authenticated][:user_id])
    #           else
    #             redirect_to(login_url) and return false
    #           end
    #         end
    #       end
    #   end
    #
    #
    # In your integration tests, you can do something like this:
    #
    #   def test_access_granted_from_xml
    #     get(
    #       "/notes/1.xml", nil,
    #       'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Bearer.encode_credentials(users(:dhh).token)
    #     )
    #
    #     assert_equal 200, status
    #   end
    #
    #
    # On shared hosts, Apache sometimes doesn't pass authentication headers to
    # FCGI instances. If your environment matches this description and you cannot
    # authenticate, try this rule in your Apache setup:
    #
    #   RewriteRule ^(.*)$ dispatch.fcgi [E=X-HTTP_AUTHORIZATION:%{HTTP:Authorization},QSA,L]
    module Bearer
      BEARER_TOKEN_KEY = 'token='
      BEARER_TOKEN_REGEX = /^Bearer /
      AUTHN_PAIR_DELIMITERS = /(?:,|;|\t+)/
      extend self

      module ControllerMethods
        def authenticate_or_request_with_http_bearer_token(realm = "Application", &login_procedure)
          authenticate_with_http_bearer_token(&login_procedure) || request_http_bearer_token_authentication(realm)
        end

        def authenticate_with_http_bearer_token(&login_procedure)
          Bearer.authenticate(self, &login_procedure)
        end

        def request_http_bearer_token_authentication(realm = "Application")
          Bearer.authentication_request(self, realm)
        end
      end

      def has_bearer_credentials?(request)
        request.authorization.present? && (auth_scheme(request) == 'Bearer')
      end

      # If bearer Authorization header is present, call the login
      # procedure with the present token and options.
      #
      # [controller]
      #   ActionController::Base instance for the current request.
      #
      # [login_procedure]
      #   Proc to call if a token is present. The Proc should take two arguments:
      #
      #     authenticate(controller) { |token, options| ... }
      #
      # Returns the return value of <tt>login_procedure</tt> if a
      # token is found. Returns <tt>nil</tt> if no token is found.

      def authenticate(controller, &login_procedure)
        token, options = bearer_token_and_options(controller.request)
        unless token.blank?
          login_procedure.call(token, options)
        end
      end

      # Parses the token and options out of the token authorization header. If
      # the header looks like this:
      #   Authorization: Bearer token="abc", nonce="def"
      # Then the returned token is "abc", and the options is {nonce: "def"}
      #
      # request - ActionDispatch::Request instance with the current headers.
      #
      # Returns an Array of [String, Hash] if a token is present.
      # Returns nil if no token is found.
      def bearer_token_and_options(request)
        authorization_request = request.authorization.to_s
        if authorization_request[BEARER_TOKEN_REGEX]
          params = bearer_token_params_from authorization_request
          [params.shift[1], Hash[params].with_indifferent_access]
        end
      end

      def bearer_token_params_from(auth)
        rewrite_param_values params_array_from raw_params auth
      end

      # Takes raw_params and turns it into an array of parameters
      def params_array_from(raw_params)
        raw_params.map { |param| param.split %r/=(.+)?/ }
      end

      # This removes the <tt>"</tt> characters wrapping the value.
      def rewrite_param_values(array_params)
        array_params.each { |param| (param[1] || "").gsub! %r/^"|"$/, '' }
      end

      # This method takes an authorization body and splits up the key-value
      # pairs by the standardized <tt>:</tt>, <tt>;</tt>, or <tt>\t</tt>
      # delimiters defined in +AUTHN_PAIR_DELIMITERS+.
      def raw_params(auth)
        _raw_params = auth.sub(BEARER_TOKEN_REGEX, '').split(/\s*#{AUTHN_PAIR_DELIMITERS}\s*/)

        if !(_raw_params.first =~ %r{\A#{BEARER_TOKEN_KEY}})
          _raw_params[0] = "#{BEARER_TOKEN_KEY}#{_raw_params.first}"
        end

        _raw_params
      end

      # Encodes the given token and options into an Authorization header value.
      #
      # token   - String token.
      # options - optional Hash of the options.
      #
      # Returns String.
      def encode_credentials(token, options = {})
        values = ["#{BEARER_TOKEN_KEY}#{token.to_s.inspect}"] + options.map do |key, value|
          "#{key}=#{value.to_s.inspect}"
        end
        "Bearer #{values * ", "}"
      end

      # Sets a WWW-Authenticate to let the client know a token is desired.
      #
      # controller - ActionController::Base instance for the outgoing response.
      # realm      - String realm to use in the header.
      #
      # Returns nothing.
      def authentication_request(controller, realm)
        controller.headers["WWW-Authenticate"] = %(Bearer realm="#{realm.gsub(/"/, "")}")
        controller.__send__ :render, :text => "HTTP Bearer Token: Access denied.\n", :status => :unauthorized
      end
    end
  end
end