# frozen_string_literal: true

##
# Authentication endpoint, protected in production by a webauth prompt
class WebauthController < ApplicationController
  before_action do
    raise CanCan::AccessDenied, 'Unable to authenticate' unless current_user
  end

  before_action :write_auth_session_info, except: [:logout]

  def login
    flash.now[:success] = 'You have been successfully logged in.'

    respond_to do |format|
      format.html { render html: '<html><script>window.close();</script></html>'.html_safe }
      format.js { render js: 'window.close();' }
    end
  end

  def logout
    session[:remote_user] = nil
    session[:workgroups] = nil
    respond_to do |format|
      format.html
    end
  end

  # TODO: we may want one method for all the below, with a referer param to know where to redirect

  def login_file
    if params[:version_id]
      redirect_to versioned_file_path(params.to_unsafe_h.symbolize_keys)
    else
      redirect_to file_path(params.to_unsafe_h.symbolize_keys)
    end
  end

  # For zip files
  def login_object
    redirect_to object_path(params.to_unsafe_h.symbolize_keys)
  end

  def login_iiif
    redirect_to iiif_path(params.to_unsafe_h.symbolize_keys)
  end

  private

  def write_auth_session_info
    session[:remote_user] = request.env['REMOTE_USER']
    session[:workgroups] = workgroups_from_env.join(';')
  end
end
