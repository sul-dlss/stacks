# frozen_string_literal: true

##
# API for delivering whole objects from stacks
class ObjectController < ApplicationController
  include Zipline

  def show
    files = accessible_files.map do |file|
      [
        file,
        file.id.file_name,
        modification_time: file.mtime
      ]
    end

    raise ActionController::RoutingError, 'No downloadable files' if files.none?

    zipline(files, "#{druid}.zip")
  end

  private

  def allowed_params
    params.permit(:id, :download)
  end

  def druid
    allowed_params[:id]
  end

  def accessible_files
    return to_enum(:accessible_files) unless block_given?

    Purl.files(druid).each do |file|
      yield file if can? :download, file
    end
  end
end
