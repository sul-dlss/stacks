class FileController < ApplicationController
  before_action :load_file
  
  def show
    fail "File Not Found" unless @file.exist?
    authorize! :read, @file
    send_file @file.path, x_sendfile: true
  end

  private

  def load_file
    @file ||= StacksFile.new(params)
  end
end