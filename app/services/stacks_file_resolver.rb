require 'byebug'

class StacksFileResolver < Riiif::FileSystemFileResolver
  def initialize(base_path:)
    @base_path = base_path
  end

  def pattern(id)
    raise ArgumentError, "Invalid characters in id `#{id}`" if id =~ /^[\-:]+$/
    ::File.join(base_path, "#{id.split('%2F').flat_map.with_index{ |element, index| index == 0 ? element.scan(/.{2}/) : element }.join('/')}/*.{#{input_types.join(',')}}")
  end
end
