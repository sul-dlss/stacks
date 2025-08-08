# frozen_string_literal: true

##
# Spec helper module to format an image server link depending on if Stacks is
# reading from OCFL or not
module ImageServerPath
  def image_server_path(druid, file_name)
    cocina = instance_double(Cocina, druid:, find_file_md5: '02f77c96c40ad3c7c843baa9c7b2ff2c')
    CGI.escape(StorageRoot.new(cocina:, file_name:).relative_path)
  end
end

RSpec.configure do |config|
  config.include ImageServerPath
end
