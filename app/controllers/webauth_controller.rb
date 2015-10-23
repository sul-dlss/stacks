##
# Authentication endpoint, protected in production by a webauth prompt
class WebauthController < ApplicationController
  before_action do
    fail CanCan::AccessDenied, 'Unable to authenticate' unless current_user
  end

  def login
    flash[:success] = 'You have been successfully logged in.'

    respond_to do |format|
      format.html { render html: '<html><script>window.close();</script></html>'.html_safe }
      format.js { render js: 'window.close();' }
    end
  end

  def login_file
    redirect_to file_path(params.symbolize_keys)
  end

  def login_iiif
    redirect_to iiif_path(params.symbolize_keys)
  end
end
