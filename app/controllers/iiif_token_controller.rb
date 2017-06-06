# API to create IIIF Authentication access tokens
class IiifTokenController < ApplicationController
  def create
    token = mint_bearer_token unless current_user.anonymous_locatable_user?

    write_bearer_token_cookie(token) if token

    @message = if token
                 {
                   accessToken: token,
                   tokenType: 'Bearer',
                   expiresIn: 3600
                 }
               else
                 { error: 'missingCredentials', description: '' }
               end

    if browser_based_client_auth?
      create_for_browser_based_client_application_auth
    else
      create_for_json_access_token_auth(token)
    end
  end

  private

  # Handle IIIF Authentication 1.0 browser-based client application requests
  # See {http://iiif.io/api/auth/1.0/#interaction-for-browser-based-client-applications}
  def create_for_browser_based_client_application_auth
    browser_params.require(:origin)

    # The browser-based interaction requires using iframes
    response.headers['X-Frame-Options'] = "ALLOW-FROM #{browser_params[:origin]}"

    @message[:messageId] = browser_params[:messageId]

    @origin = browser_params[:origin]

    render 'create', layout: false
  end

  # Handle IIIF Authentication 1.0 JSON Access Token requests
  # See {http://iiif.io/api/auth/1.0/#the-json-access-token-response}
  def create_for_json_access_token_auth(token)
    respond_to do |format|
      format.html { redirect_to callback: callback_value, format: 'js' }
      format.js do
        status = if callback_value || token
                   :ok
                 else
                   :unauthorized
                 end

        render json: @message.to_json, callback: callback_value, status: status
      end
    end
  end

  def json_params
    params.permit(:callback)
  end

  def browser_params
    params.permit(:messageId, :origin)
  end

  def browser_based_client_auth?
    browser_params[:messageId].present?
  end

  def callback_value
    json_params[:callback]
  end

  def mint_bearer_token
    encode_credentials(current_user.token).sub('Bearer ', '')
  end

  def write_bearer_token_cookie(token)
    # webauth users already have a webauth cookie; no additional cookie needed
    return if current_user.webauth_user?

    cookies[:bearer_token] = {
      value: token,
      expires: 1.hour.from_now,
      httponly: true,
      secure: request.ssl?
    }
  end
end
