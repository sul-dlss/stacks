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
end
