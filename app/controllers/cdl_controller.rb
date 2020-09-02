# frozen_string_literal: true

##
# Controlled digital lending endpoint (also protected in production by shibboleth)
class CdlController < ApplicationController
  before_action do
    raise CanCan::AccessDenied, 'Unable to authenticate' unless current_user
  end
  skip_forgery_protection only: [:show, :show_options]

  before_action :write_auth_session_info, only: [:create]
  before_action :validate_token, only: [:delete]

  # Render some information about an active CDL token so the viewer can display e.g.
  # the current due date.
  def show
    render json: {
      payload: payload&.except(:token),
      availability_url: ("#{Settings.cdl.url}/availability/#{barcode}" if barcode)
    }.reject { |_k, v| v.blank? }
  end

  def show_options
    response.headers['Access-Control-Allow-Headers'] = 'Authorization'
    self.response_body = ''
  end

  # rubocop:disable Metrics/AbcSize
  # "Check out" a book for controlled digital lending:
  #   - authenicate the user using shibboleth (so we know they're eligible for CDL)
  #   - get the Symphony barcode of the digital item
  #   - bounce the user over to requests to perform the Symphony hold + check out
  #  THEN, the user gets bounced back to us with a token that represents their successful checkout
  #    (and coincidentally is also stored + used as the IIIF access cookie)
  #    The JWT token will contain:
  #      - jti (circ record key)
  #      - sub (sunetid)
  #      - aud (druid)
  #      - exp (due date)
  #      - barcode (note: the actual item barcode may differ from the one in the SDR item)
  def create
    if params[:token]
      current_user.append_jwt_token(params[:token])
      cookies.encrypted[:tokens] = current_user.jwt_tokens

      respond_to do |format|
        format.html { render html: '<html><script>window.close();</script></html>'.html_safe }
        format.js { render js: 'window.close();' }
      end
    else
      render json: 'invalid barcode', status: 400 and return unless barcode

      checkout_params = {
        id: params[:id],
        barcode: barcode,
        modal: true,
        return_to: cdl_checkout_iiif_auth_api_url(params[:id])
      }

      redirect_to "#{Settings.cdl.url}/checkout?#{checkout_params.to_param}"
    end
  end

  # "Check in" a book from controlled digital lending
  # As with #create, we bounce the user to requests to handle the Symphony interaction,
  # and after they come back we'll clean up cookies + tokens on this end.
  def delete
    token = payload[:token]

    if params[:success]
      cookies.encrypted[:tokens] = (cookies.encrypted[:tokens] || []) - [token]

      respond_to do |format|
        format.html { render html: '<html><script>window.close();</script></html>'.html_safe }
        format.js { render js: 'window.close();' }
      end
    else
      checkin_params = { token: token, return_to: cdl_checkin_iiif_auth_api_url(params[:id]) }
      redirect_to "#{Settings.cdl.url}/checkin?#{checkin_params.to_param}"
    end
  end
  # rubocop:enable Metrics/AbcSize

  def renew
    if params[:token]
      current_user.append_jwt_token(params[:token])
      cookies.encrypted[:tokens] = current_user.jwt_tokens

      respond_to do |format|
        format.html { render html: '<html><script>window.close();</script></html>'.html_safe }
        format.js { render js: 'window.close();' }
      end
    else
      token = payload[:token]

      renew_params = { token: token, return_to: cdl_renew_iiif_auth_api_url(params[:id]) }
      redirect_to "#{Settings.cdl.url}/renew?#{renew_params.to_param}"
    end
  end

  private

  def write_auth_session_info
    return if session[:remote_user]

    session[:remote_user] = request.env['REMOTE_USER']
    session[:workgroups] = workgroups_from_env.join(';')
  end

  def payload
    @payload ||= current_user.cdl_tokens.find { |token| token[:aud] == params[:id] }&.with_indifferent_access
  end

  def validate_token
    render json: 'Token not found', status: :bad_request if payload.blank?
  end

  def barcode
    @barcode ||= begin
      return payload&.dig('barcode') if payload&.dig('barcode')

      public_xml = Purl.public_xml(params[:id])
      doc = Nokogiri::XML.parse(public_xml)
      barcode = doc.xpath('//identityMetadata/sourceId[@source="sul"]')&.text&.sub(/^stanford_/, '')

      barcode if barcode.starts_with?('36105')
    end
  end
end
