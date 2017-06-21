##
# RightsMetadata interpretation
module StacksRights
  def world_unrestricted?
    rights.world_unrestricted_file? file_name
  end

  def world_downloadable?
    rights.world_downloadable_file? file_name
  end

  # Returns [<Boolean>, <String>]: whether a file-level world node exists, and the value of its rule attribute
  #   If a world node does not exist for this file, then object-level world rights are returned
  def world_rights
    rights.world_rights_for_file file_name
  end

  # Returns [<Boolean>, <String>]: whether a file-level group/stanford node exists, and the value of its rule attribute
  #   If a group/stanford node does not exist for this file, then object-level group/stanford rights are returned
  def stanford_only_rights
    rights.stanford_only_rights_for_file file_name
  end

  def stanford_only_downloadable?
    rights.stanford_only_downloadable_file? file_name
  end

  # Returns true if the file is stanford-only readable AND has no rule attribute
  #   If a stanford node does not exist for this file, then object-level stanford rights are returned
  def stanford_only_unrestricted?
    rights.stanford_only_unrestricted_file? file_name
  end

  def maybe_downloadable?
    world_unrestricted? || stanford_only_unrestricted?
  end

  # Returns [<Boolean>, <String>]: whether a file-level agent node exists, and the value of its rule attribute
  #   If an agent node does not exist for this file, then object-level agent rights are returned
  def agent_rights(agent)
    rights.agent_rights_for_file file_name, agent
  end

  def agent_downloadable?(agent)
    value, rule = agent_rights(agent)
    value && (rule.nil? || rule != Dor::RightsAuth::NO_DOWNLOAD_RULE)
  end

  # Returns true if a given file has any location restrictions.
  #   Falls back to the object-level behavior if none at file level.
  def restricted_by_location?
    rights.restricted_by_location?(file_name)
  end

  # Returns [<Boolean>, <String>]: whether a file-level location exists, and the value of its rule attribute
  #   If a location node does not exist for this file, then object-level location rights are returned
  def location_rights(location)
    rights.location_rights_for_file(file_name, location)
  end

  def location_downloadable?(location)
    value, rule = location_rights(location)
    value && (rule.nil? || rule != Dor::RightsAuth::NO_DOWNLOAD_RULE)
  end

  def rights
    @rights ||= Dor::RightsAuth.parse(rights_xml)
  end

  private

  def rights_xml
    Rails.cache.fetch("stacks_file/#{druid}-#{etag}/rights_xml", expires_in: 10.minutes) do
      benchmark "Fetching public xml for #{druid}" do
        Faraday.get(Settings.purl.url + "/#{druid}.xml").body
      end
    end
  end

  def logger
    Rails.logger
  end
end
