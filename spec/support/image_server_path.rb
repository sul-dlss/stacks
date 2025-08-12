# frozen_string_literal: true

##
# Spec helper module to format an image server link depending on if Stacks is
# reading from OCFL or not
module ImageServerPath
  def image_server_path(druid, file_name)
    cocina = instance_double(Cocina, druid:, find_file_md5: '8ff299eda08d7c506273840d52a03bf3')
    CGI.escape(StorageRoot.new(cocina:, file_name:).relative_path)
  end
end

RSpec.configure do |config|
  config.include ImageServerPath
end
