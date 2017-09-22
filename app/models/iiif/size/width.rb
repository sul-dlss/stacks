module Iiif
  module Size
    # The image or region should be scaled so that its width is exactly equal
    # to the provided parameter, and the height will be a calculated value that
    # maintains the aspect ratio of the extracted region
    class Width
      # @param [Integer] width
      def initialize(width)
        @width = width
      end

      attr_reader :width
    end
  end
end
