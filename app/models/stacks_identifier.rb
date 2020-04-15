# frozen_string_literal: true

# The identifier of a stacks resource
class StacksIdentifier
  attr_reader :druid, :file_name, :options

  OPTIONS_DELIMITER = '%2F!attr!%2F'
  def initialize(identifier = nil, id: nil, druid: nil, file_name: nil, file_ext: nil, **options)
    if identifier
      parse_identifer(identifier, file_ext)
    elsif id
      parse_identifer(id, file_ext)
    elsif druid && file_name
      self.druid = druid
      @file_name = [file_name, file_ext.presence].compact.join('.')
    end
    @options = (@options || {}).merge(options)
  end

  def to_s
    identifier_part = [@druid, @file_name].join('%2F')
    options_part = @options.map { |k, v| "#{k}=#{v}" }.join('%2F')

    [identifier_part, options_part.presence].compact.join(OPTIONS_DELIMITER)
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

  def treeified_path
    File.join(druid_parts[1..4], file_name)
  end

  private

  attr_reader :druid_parts

  def druid=(druid)
    @druid = druid.sub(/^druid:/, '')
    match = @druid.match(/^([a-z]{2})(\d{3})([a-z]{2})(\d{4})$/i)
    @druid_parts = match
  end

  def parse_identifer(id, file_ext)
    identifier_and_file_name, attrs = id.split(OPTIONS_DELIMITER, 2)
    druid, file_name = identifier_and_file_name.split('%2F', 2)
    self.druid = druid
    @file_name = [file_name, file_ext.presence].compact.join('.')

    if attrs.present?
      @options = attrs.split('%2F').map { |x| x.split('=', 2) }.to_h
    end
  end
end
