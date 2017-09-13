# frozen_string_literal: true

# @abstract Fetch image information
# Extend this class for each implementation that can get image information.
class InfoService
  # @param image [#path,#canonical_url]
  def initialize(image)
    @image = image
  end

  attr_reader :image

  delegate :id, :file_name, to: :image
end
