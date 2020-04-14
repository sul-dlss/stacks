# frozen_string_literal: true

# API to create IIIF Authentication access tokens
class IiifTokenController < ApplicationController
  skip_forgery_protection

  def create
    token = mint_bearer_token if token_eligible_user?

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

  # An authenticated user can retrieve a token if they are logged in with webauth, as an
  # app-user, or are accessing material from a location-specific kiosk.
  # Other anonymous users are not eligible.
  def token_eligible_user?
    current_user.token_user? || current_user.webauth_user? || current_user.app_user? || current_user.location?
  end

  # Handle IIIF Authentication 1.0 browser-based client application requests
  # See {http://iiif.io/api/auth/1.0/#interaction-for-browser-based-client-applications}
  def create_for_browser_based_client_application_auth
    browser_params.require(:origin)

    # The browser-based interaction requires using iframes
    # We disable this header (added by default) entirely to ensure
    # that IIIF viewers embedded by iframes in other pages will
    # work as expected.
    response.headers['X-Frame-Options'] = ""

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
    encode_credentials(current_user.token).sub('Token ', '')
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
