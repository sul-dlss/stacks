class StacksFileResolver < Riiif::FileSystemFileResolver
  def initialize(base_path:)
    @base_path = base_path
  end

  def pattern(id)
    raise ArgumentError, "Invalid characters in id `#{id}`" unless id =~ /^[\w\-:]+$/
    ::File.join(base_path, "#{id}/*.{#{input_types.join(',')}}")
  end
end
