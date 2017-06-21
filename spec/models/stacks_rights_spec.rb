require 'rails_helper'

describe StacksRights do
  subject(:stacks_rights) do
    Class.new do
      attr_reader :file_name

      def initialize(rights_xml, file_name)
        @rights = Dor::RightsAuth.parse(rights_xml)
        @file_name = file_name
      end

      include StacksRights
    end.new(rights_xml, file_name)
  end
  let(:rights_xml) { '' }
  let(:file_name) { 'abc.pdf' }

  describe '#restricted_locations' do
    let(:rights_xml) do
      <<-XML
      <rightsMetadata>
        <access type="read">
          <machine>
            <location>location1</location>
          </machine>
        </access>
      </rightsMetadata>
      XML
    end

    it 'enumerates locations the item can be accessed' do
      expect(subject.restricted_locations).to match_array ['location1']
    end

    context 'with file-level rights' do
      let(:rights_xml) do
        <<-XML
        <rightsMetadata>
          <access type="read">
            <file>abc.pdf</file>
            <machine>
              <location>location2</location>
            </machine>
          </access>
          <access type="read">
            <machine>
              <location>location1</location>
            </machine>
          </access>
        </rightsMetadata>
        XML
      end

      it 'enumerates file-level locations the item can be accessed' do
        expect(subject.restricted_locations).to match_array ['location2']
      end
    end
  end
end
