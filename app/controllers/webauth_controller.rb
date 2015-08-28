class WebauthController < ApplicationController
  include ActionController::Redirecting
  include Rails.application.routes.url_helpers

  def login_file
    redirect_to file_path(params)
  end

  def login_iiif
    redirect_to iiif_path(params)
  end
end