module Iiif
  module Region
    # Represents an absolute specified region
    class Absolute
      # @param [Integer] x
      # @param [Integer] y
      # @param [Integer] width
      # @param [Integer] height
      def initialize(x, y, width, height)
        @offset_x = x
        @offset_y = y
        @width = width
        @height = height
      end

      attr_reader :width, :height

      # TODO: Dimension object?
      def dimensions
        [width, height]
      end
    end
  end
end
