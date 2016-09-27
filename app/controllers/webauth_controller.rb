##
# Authentication endpoint, protected in production by a webauth prompt
class WebauthController < ApplicationController
  before_action do
    raise CanCan::AccessDenied, 'Unable to authenticate' unless current_user
  end

  def login
    flash[:success] = 'You have been successfully logged in.'

    respond_to do |format|
      format.html { render html: '<html><script>window.close();</script></html>'.html_safe }
      format.js { render js: 'window.close();' }
    end
  end

  # TODO: we may want one method for all the below, with a referer param to know where to redirect
  # TODO: can't think of a reasonable way to do strong params here

  def login_file
    redirect_to file_path(params.to_unsafe_h.symbolize_keys)
  end

  def login_iiif
    redirect_to iiif_path(params.to_unsafe_h.symbolize_keys)
  end
end
