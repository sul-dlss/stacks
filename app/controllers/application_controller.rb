class ApplicationController < ActionController::Metal
  include AbstractController::Callbacks
  include CanCan::ControllerAdditions

  include Squash::Ruby::ControllerMethods
  enable_squash_client

  def current_user
    @current_user ||= User.new(id: request.remote_user, webauth_user: true) if request.remote_user
  end
end
