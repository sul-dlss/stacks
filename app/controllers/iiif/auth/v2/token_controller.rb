# frozen_string_literal: true

# API to create IIIF Authentication access tokens
module Iiif
  module Auth
    module V2
      # Creates tokens for IIIF auth v2
      # https://iiif.io/api/auth/2.0/#access-token-service
      class TokenController < ApplicationController
        skip_forgery_protection

        # Returns an HTML response that posts back to the parent window
        # See {https://iiif.io/api/auth/2.0/#workflow-from-the-browser-client-perspective}
        def create
          params.require(%i[origin messageId])

          token = mint_bearer_token if token_eligible_user?

          @message = if token
                       {
                         "@context" => "http://iiif.io/api/auth/2/context.json",
                         type: 'AuthAccessToken2',
                         accessToken: token,
                         expiresIn: 3600, # The number of seconds until the token ceases to be valid. (3600 = 1 hr)
                         messageId: params[:messageId]
                       }
                     else
                       {
                         "@context" => "http://iiif.io/api/auth/2/context.json",
                         type: 'AuthAccessTokenError2',
                         profile: 'missingAspect',
                         heading: "Missing credentials",
                         messageId: params[:messageId]
                       }
                     end

          # The browser-based interaction requires using iframes
          # We disable this header (added by default) entirely to ensure
          # that IIIF viewers embedded by iframes in other pages will
          # work as expected.
          response.headers['X-Frame-Options'] = ""

          @origin = params[:origin]

          render 'create', layout: false
        end

        private

        # An authenticated user can retrieve a token if they are logged in with webauth,
        # or are accessing material from a location-specific kiosk.
        # Other anonymous users are not eligible.
        def token_eligible_user?
          current_user.webauth_user? || current_user.location?
        end

        def mint_bearer_token
          "#{ActionController::HttpAuthentication::Token::TOKEN_KEY}#{current_user.token.to_s.inspect}"
        end
      end
    end
  end
end
