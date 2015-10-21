##
# Authentication endpoint, protected in production by a webauth prompt
class WebauthController < ApplicationController
  before_action do
    fail CanCan::AccessDenied, 'Unable to authenticate' unless request.remote_user
  end

  def login_file
    redirect_to file_path(params.symbolize_keys)
  end

  def login_iiif
    redirect_to iiif_path(params.symbolize_keys)
  end
end
