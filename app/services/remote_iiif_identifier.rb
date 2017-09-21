# frozen_string_literal: true

# Convert StacksIdentifier into the iiif identifier on the remote server
class RemoteIiifIdentifier
  # @param id [StacksIdentifier]
  # @return [String]
  def self.convert(id)
    CGI.escape(id.treeified_path)
  end
end
