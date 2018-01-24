module RightsXMLFixtures
  def world_readable_rights_xml
    <<-XML
      <publicObject>
        <rightsMetadata>
          <access type="read">
            <machine>
              <world/>
            </machine>
          </access>
        </rightsMetadata>
      </publicObject>
    XML
  end

  def stanford_restricted_rights_xml
    <<-XML
      <publicObject>
        <rightsMetadata>
          <access type="read">
            <machine>
              <group>Stanford</group>
            </machine>
          </access>
        </rightsMetadata>
      </publicObject>
    XML
  end

  def world_no_download_xml
    <<-XML
      <publicObject>
        <rightsMetadata>
          <access type="read">
            <machine>
              <world rule="no-download"/>
            </machine>
          </access>
        </rightsMetadata>
      </publicObject>
    XML
  end

  def stanford_only_no_download_xml
    <<-XML
      <publicObject>
        <rightsMetadata>
          <access type="read">
            <machine>
              <group rule="no-download">stanford</group>
            </machine>
          </access>
        </rightsMetadata>
      </publicObject>
    XML
  end

  def location_rights_xml
    <<-XML
      <publicObject>
        <rightsMetadata>
          <access type="read">
            <machine>
              <location>location1</location>
            </machine>
          </access>
        </rightsMetadata>
      </publicObject>
    XML
  end

  def location_thumbnail_rights_xml
    <<-XML
      <publicObject>
        <rightsMetadata>
          <access type="read">
            <machine>
              <location>location1</location>
            </machine>
          </access>
        </rightsMetadata>
        <thumb>nr349ct7889/nr349ct7889_00_0001.jp2</thumb>
      </publicObject>
    XML
  end
end
