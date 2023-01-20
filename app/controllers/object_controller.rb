# frozen_string_literal: true

##
# API for delivering whole objects from stacks
class ObjectController < ApplicationController
  include Zipline

  # Return a zip of all the files if they have access to all the files.
  # This will force a login if any of the files is not access=world
  def show
    files = Purl.files(druid)
    raise ActionController::RoutingError, 'No downloadable files' if files.none?

    files.each do |file|
      authorize! :download, file
    end
    zip_contents = files.map do |file|
      [
        file,
        file.file_name,
        modification_time: file.mtime
      ]
    end

    zipline(zip_contents, "#{druid}.zip")
  end

  private

  def druid
    params[:id]
  end

  # called when CanCan::AccessDenied error is raised by authorize!
  #   Should only be here if
  #   a)  access not allowed (send to super)  OR
  #   b)  need user to login to determine if access allowed
  def rescue_can_can(exception)
    current_file = exception.subject
    if User.stanford_generic_user.ability.can?(:access, current_file) && !current_user.webauth_user?
      redirect_to auth_object_path(id: druid)
    else
      super
    end
  end
end
