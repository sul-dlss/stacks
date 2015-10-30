##
# RightsMetadata interpretation
module StacksRights
  def world_unrestricted?
    rights.world_unrestricted_file? file_name
  end

  def world_rights
    rights.world_rights_for_file file_name
  end

  def stanford_only_rights
    rights.stanford_only_rights_for_file file_name
  end

  def stanford_only_unrestricted?
    rights.stanford_only_unrestricted_file? file_name
  end

  def maybe_downloadable?
    world_unrestricted? || stanford_only_unrestricted?
  end

  def agent_rights(agent)
    rights.agent_rights_for_file file_name, agent
  end

  def rights
    @rights ||= Dor::RightsAuth.parse(rights_xml)
  end

  private

  def rights_xml
    Rails.cache.fetch("stacks_file/#{druid}-#{etag}/rights_xml", expires_in: 10.minutes) do
      benchmark "Fetching public xml for #{druid}" do
        Hurley.get(Settings.purl.url + "/#{druid}.xml").body
      end
    end
  end

  def logger
    Rails.logger
  end
end
