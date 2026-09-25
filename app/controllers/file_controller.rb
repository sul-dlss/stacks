# frozen_string_literal: true

##
# API for delivering files from stacks
# rubocop:disable Metrics/ClassLength
class FileController < ApplicationController
  rescue_from ActionController::MissingFile do
    render plain: 'File not found', status: :not_found
  end

  # rubocop:disable Metrics/AbcSize
  def show
    return unless stale?(**cache_headers)

    authorize! :download, current_file
    expires_in 10.minutes
    response.headers['Accept-Ranges'] = 'bytes'
    response.headers['Access-Control-Expose-Headers'] = 'Content-Range'
    response.headers.delete('X-Frame-Options')

    TrackDownloadJob.perform_later(
      druid: current_file.id,
      file: current_file.file_name,
      user_agent: request.user_agent,
      ip: request.remote_ip
    )

    # Handle range requests. Not used for HEAD requests.
    if request.headers['Range'].present? && !request.head?
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

    response.headers['Content-Range'] = "bytes #{range}/#{current_file.content_length}"

    stream_file(status: :partial_content, content_length: range.content_length) do |write|
      current_file.s3_range(range: range.s3_range) { |chunk| write.call(chunk) }
    end
  end

  def handle_full_request
    stream_file(status: :ok, content_length: current_file.content_length) do |write|
      current_file.s3_object { |chunk| write.call(chunk) }
    end
  end

  # Stream the file from S3 as a response with a Content-Length.
  # A HEAD request gets the same headers as a GET, but doesn't fetch anything from S3.
  def stream_file(status:, content_length:, &)
    response.headers['Content-Type'] = file_content_type
    response.headers['Content-Disposition'] =
      ActionDispatch::Http::ContentDisposition.format(disposition:, filename: current_file.file_name)
    response.headers['Content-Length'] = content_length.to_s
    return head(status) if request.head?

    self.status = status
    self.response_body = streaming_body(&)
  end

  # Send content as an Enumerable Rack body. ActionController::Live deletes the
  # content-length header before writing the first chunk, so it strips information
  # from both HEAD and GET requests.
  def streaming_body
    Enumerator.new do |yielder|
      write_error = nil
      write = lambda do |chunk|
        yielder << chunk
      rescue StandardError => e
        write_error = e
        raise
      end

      yield write
    rescue StandardError => e
      # The web server couldn't send a chunk, so the client went away. Clients are allowed to
      # disconnect and we don't need to hear about it. Re-raise the web server's own error
      # (the S3 client may have wrapped it) so that it can deal with the connection.
      raise write_error if write_error

      Honeybadger.notify(e)
      raise
    end
  end

  # Same implementation as in ActionController::Live#send_stream
  def file_content_type
    current_file.content_type ||
      Mime::Type.lookup_by_extension(File.extname(current_file.file_name).downcase.delete('.'))&.to_s ||
      'application/octet-stream'
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
    @cocina ||= Cocina.find(params.expect(:id), version)
  end

  def version
    params[:version_id] || :head
  end
end
# rubocop:enable Metrics/ClassLength
