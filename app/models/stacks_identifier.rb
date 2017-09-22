# frozen_string_literal: true

# The identifier of a stacks resource
class StacksIdentifier
  def initialize(options = {})
    if options.is_a? String
      parse_identifer(options)
    elsif options[:id]
      parse_identifer(options[:id])
    elsif options[:druid] && options[:file_name]
      self.druid = options[:druid]
      @file_name = options[:file_name]
    end
  end

  def to_s
    [@druid, @file_name].join('%2F')
  end

  def ==(other)
    other.class == self.class &&
      other.druid == druid &&
      other.file_name == file_name
  end

  def valid?
    return true if druid_parts && file_name
    false
  end

  def file_name_without_ext
    File.basename(file_name, '.*')
  end

  def has_file_name_extension?
    File.extname(file_name).present?
  end

  def treeified_path
    File.join(druid_parts[1..4], file_name)
  end

  attr_reader :druid, :file_name

  private

  attr_reader :druid_parts

  def druid=(druid)
    @druid = druid.sub(/^druid:/, '')
    match = @druid.match(/^([a-z]{2})(\d{3})([a-z]{2})(\d{4})$/i)
    @druid_parts = match
  end

  def parse_identifer(id)
    druid, @file_name = id.split('%2F', 2)
    self.druid = druid
  end
end
