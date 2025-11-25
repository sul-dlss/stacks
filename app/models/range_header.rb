# frozen_string_literal: true

# Parses an HTTP Range header
class RangeHeader
  Range = Data.define(:range_start, :range_end) do
    def content_length
      range_end - range_start + 1
    end

    def to_s
      "#{range_start}-#{range_end}"
    end

    def s3_range
      "bytes=#{self}"
    end
  end

  def initialize(range_header, content_length)
    @range_header = range_header
    @content_length = content_length
  end

  def invalid?
    return true unless range_header&.start_with?('bytes=')

    ranges.empty?
  end

  def ranges
    @ranges ||= parse_range_header
  end

  private

  attr_reader :content_length, :range_header

  def range_specs
    range_header[6..].split(',').map(&:strip)
  end

  def parse_range_header
    range_specs.filter_map do |range_spec|
      next unless range_spec.include?('-')

      start_str, end_str = range_spec.split('-', 2)

      if start_str.empty?
        # Suffix range: -500 (last 500 bytes)
        suffix_range(end_str.to_i)
      elsif end_str.empty?
        # Prefix range: 500- (from byte 500 to end)
        prefix_range(start_str.to_i)
      else
        # Full range: 500-1000
        full_range(start_str.to_i, end_str.to_i)
      end
    end
  end

  def prefix_range(range_start)
    return if range_start.negative? || range_start >= content_length

    range_end = content_length - 1
    Range.new(range_start, range_end)
  end

  def suffix_range(suffix_length)
    return if suffix_length <= 0

    range_start = [content_length - suffix_length, 0].max
    range_end = content_length - 1
    Range.new(range_start, range_end)
  end

  def full_range(range_start, range_end)
    return if range_start.negative? || range_end < range_start || range_start >= content_length

    # Clamp range_end to content_length - 1
    range_end = [range_end, content_length - 1].min
    Range.new(range_start, range_end)
  end
end
