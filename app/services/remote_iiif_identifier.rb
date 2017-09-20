# frozen_string_literal: true

# Convert StacksIdentifier into the iiif identifier on the remote server
class RemoteIiifIdentifier
  # @param id [StacksIdentifier]
  # @return [String]
  def self.convert(id)
    pth = PathService.for(id)
    CGI.escape(pth.sub("#{Settings.stacks.storage_root}/", ''))
  end
end
