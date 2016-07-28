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
end
