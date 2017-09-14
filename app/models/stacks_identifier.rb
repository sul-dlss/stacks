# The identifier of a stacks resource
class StacksIdentifier
  def initialize(options = {})
    if options.is_a? String
      @druid, @file_name = options.sub(/^druid:/, '').split('%2F', 2)
    elsif options[:id]
      @druid, @file_name = options[:id].sub(/^druid:/, '').split('%2F', 2)
    elsif options[:druid] && options[:file_name]
      @druid = options[:druid].sub(/^druid:/, '')
      @file_name = options[:file_name]
    end
  end

  def to_s
    [@druid, @file_name].join('%2F')
  end

  attr_reader :druid, :file_name
end
