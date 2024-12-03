# frozen_string_literal: true

##
# API for delivering whole objects from stacks
class ObjectController < ApplicationController
  # Return a zip of all the files if they have access to all the files.
  # This will force a login if any of the files is not access=world
  def show
    cocina = Cocina.find(druid, version)
    files = cocina.files
    raise ActionController::RoutingError, 'No downloadable files' if files.none?

    files.each do |file|
      authorize! :download, file
    end

    track_download

    zip_kit_stream(filename: "#{druid}.zip") do |zip|
      files.each do |stacks_file|
        zip.write_file(stacks_file.file_name, modification_time: stacks_file.mtime) do |sink|
          File.open(stacks_file.path, "rb") { |file_input| IO.copy_stream(file_input, sink) }
        end
      end
    end
  end

  private

  def track_download
    TrackDownloadJob.perform_later(
      druid:,
      user_agent: request.user_agent,
      ip: request.remote_ip
    )
  end

  def druid
    params[:id]
  end

  def version
    params[:version_id] || :head
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
