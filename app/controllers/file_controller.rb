# frozen_string_literal: true

##
# API for delivering files from stacks
class FileController < ApplicationController
  include ActionController::Live

  rescue_from ActionController::MissingFile do
    render plain: 'File not found', status: :not_found
  end

  # rubocop:disable Metrics/AbcSize
  def show
    return unless stale?(**cache_headers)

    authorize! :download, current_file
    expires_in 10.minutes
    response.headers['Accept-Ranges'] = 'bytes'
    response.headers.delete('X-Frame-Options')

    TrackDownloadJob.perform_later(
      druid: current_file.id,
      file: current_file.file_name,
      user_agent: request.user_agent,
      ip: request.remote_ip
    )

    # Handle range requests
    if request.headers['Range'].present?
      handle_range_request
    else
      handle_full_request
    end
  end
  # rubocop:enable Metrics/AbcSize

  def options
    response.headers['Access-Control-Allow-Methods'] = 'GET, OPTIONS'
    response.headers['Access-Control-Allow-Headers'] = 'Range'
    response.headers['Access-Control-Max-Age'] = 1.day.to_i

    head :ok
  end

  private

  def handle_range_request # rubocop:disable Metrics/AbcSize
    range_header = RangeHeader.new(request.headers['Range'], current_file.content_length)

    if range_header.invalid?
      # Invalid range, return 416 Range Not Satisfiable
      response.headers['Content-Range'] = "bytes */#{current_file.content_length}"
      head :range_not_satisfiable
      return
    end

    # For simplicity, handle only single range requests
    # Multi-range requests would require multipart/byteranges response
    range = range_header.ranges.first

    response.status = 206
    response.headers['Content-Range'] = "bytes #{range}/#{current_file.content_length}"
    response.headers['Content-Length'] = range.content_length.to_s

    send_stream(
      filename: current_file.file_name,
      type: current_file.content_type,
      disposition:
    ) do |stream|
      current_file.s3_range(range: range.s3_range) do |chunk|
        stream.write(chunk)
      end
    end
  end

  def handle_full_request
    response.headers['Content-Length'] = current_file.content_length.to_s

    send_stream(
      filename: current_file.file_name,
      type: current_file.content_type,
      disposition:
    ) do |stream|
      current_file.s3_object do |chunk|
        stream.write(chunk)
      end
    end
  end

  def disposition
    return :attachment if file_params[:download]

    :inline
  end

  def file_params
    params.permit(:id, :file_name, :download, :version_id)
  end

  # called when CanCan::AccessDenied error is raised, typically by authorize!
  #   Should only be here if
  #   a)  access not allowed (send to super)  OR
  #   b)  need user to login to determine if access allowed
  def rescue_can_can(exception)
    if User.stanford_generic_user.ability.can?(:access, current_file) && !current_user.webauth_user?
      redirect_to auth_file_url(file_params.to_h.symbolize_keys)
    else
      super
    end
  end

  def cache_headers
    {
      etag: [current_file.etag, current_user.try(:etag)],
      last_modified: current_file.mtime,
      public: anonymous_ability.can?(:download, current_file),
      template: false
    }
  end

  def current_file
    @file ||= StacksFile.new(file_name: params[:file_name], cocina:)
  end

  def cocina
    @cocina ||= Cocina.find(params[:id], version)
  end

  def version
    params[:version_id] || :head
  end
end
