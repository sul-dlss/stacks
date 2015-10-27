# API to create IIIF Authentication access tokens
class IiifTokenController < ApplicationController
  # rubocop:disable Metrics/MethodLength, Metrics/PerceivedComplexity
  def create
    token = mint_bearer_token if current_user

    write_bearer_token_cookie(token) if token

    respond_to do |format|
      format.html { redirect_to format: 'json' }
      format.json do
        response = if token
                     {
                       accessToken: token,
                       tokenType: 'Bearer',
                       expiresIn: 3600
                     }
                   else
                     { error: 'missingCredentials', description: '' }
                   end

        status = if request.xhr? || token
                   :ok
                 else
                   :unauthorized
                 end

        render json: response.to_json, callback: params[:callback], status: status
      end
    end
  end
  # rubocop:enable Metrics/MethodLength, Metrics/PerceivedComplexity

  private

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
