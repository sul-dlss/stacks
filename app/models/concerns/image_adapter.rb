# Common methods for projections (StacksImage, StacksMediaStream) that
# are backed by a file on disk.
module ImageAdapter
  extend ActiveSupport::Concern
  include ActiveModel::Model

  # @return [StacksFile] the file on dis that back this projection
  def resolver
    @resolver ||= ImageResolver.new(name: 'djatoka', path: file.path).resolver
  end

  delegate :metadata, to: :resolver
end
