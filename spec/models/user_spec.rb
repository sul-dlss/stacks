require 'rails_helper'

# These specs are a rather integration-y approach to testing ability.rb, since they rely
# on the dor-rights-auth parsing that actually gets used in the real world.  Essentially
# a giant truth table for the various combinations of object rights, object types, and user
# types that permission checking might deal with.  This is not a comprehensive listing of
# all possible permutations, but it should cover all the basics, and a number of representitive
# corner cases.  This is in lieu of the more unit test style of an ability_spec.rb.
describe User do
  describe 'abilities' do
    subject(:ability) { Ability.new(user) }
    let(:user) { nil }

    let(:rights_xml) { '' }
    let(:file) do
      StacksFile.new(file_name: 'file.csv').tap { |x| allow(x).to receive(:rights_xml).and_return(rights_xml) }
    end
    let(:image) do
      StacksImage.new(file_name: 'image.jpg').tap { |x| allow(x).to receive(:rights_xml).and_return(rights_xml) }
    end
    let(:media) do
      StacksMediaStream.new(file_name: 'movie.mp4').tap { |x| allow(x).to receive(:rights_xml).and_return(rights_xml) }
    end

    let(:thumbnail_transformation) { IiifTransformation.new(region: 'full', size: '!400,400') }
    let(:thumbnail) { StacksImage.new(transformation: thumbnail_transformation) }

    let(:square_transformation) { IiifTransformation.new(region: 'square', size: '!400,400') }
    let(:square_thumbnail) { StacksImage.new(transformation: square_transformation) }

    let(:tile_transformation) { IiifTransformation.new(region: '0,0,100,100', size: '256,256') }
    let(:tile) { StacksImage.new(transformation: tile_transformation) }

    before do
      allow_any_instance_of(StacksImage).to receive(:rights_xml).and_return(rights_xml)
    end

    context 'for a stanford webauth user' do
      let(:user) { User.new(id: 'a', webauth_user: true, ldap_groups: %w(stanford:stanford)) }

      context 'with a world-readable file' do
        let(:rights_xml) do
          <<-EOF.strip_heredoc
          <rightsMetadata>
              <access type="read">
                <machine>
                  <world/>
                </machine>
              </access>
            </rightsMetadata>
          EOF
        end
        it { is_expected.to be_able_to(:download, file) }
        it { is_expected.to be_able_to(:download, image) }
        it { is_expected.to be_able_to(:download, media) }
        it { is_expected.to be_able_to(:read, file) }
        it { is_expected.to be_able_to(:read, image) }
        it { is_expected.to be_able_to(:read, media) }
        it { is_expected.to be_able_to(:read, tile) }
        it { is_expected.to be_able_to(:stream, media) }
        it { is_expected.to be_able_to(:access, file) }
        it { is_expected.to be_able_to(:read_metadata, image) }
        it { is_expected.to be_able_to(:read, thumbnail) }
        it { is_expected.to be_able_to(:read, square_thumbnail) }
      end

      context 'with a stanford-only file' do
        let(:rights_xml) do
          <<-EOF.strip_heredoc
          <rightsMetadata>
            <access type="read">
              <machine>
                <group>Stanford</group>
              </machine>
            </access>
          </rightsMetadata>
          EOF
        end
        it { is_expected.to be_able_to(:download, file) }
        it { is_expected.to be_able_to(:download, image) }
        it { is_expected.to be_able_to(:download, media) }
        it { is_expected.to be_able_to(:read, file) }
        it { is_expected.to be_able_to(:read, image) }
        it { is_expected.to be_able_to(:read, media) }
        it { is_expected.to be_able_to(:read, tile) }
        it { is_expected.to be_able_to(:stream, media) }
        it { is_expected.to be_able_to(:access, file) }
        it { is_expected.to be_able_to(:read_metadata, image) }
        it { is_expected.to be_able_to(:read, thumbnail) }
        it { is_expected.to be_able_to(:read, square_thumbnail) }
      end

      context 'with read rights but not download' do
        let(:rights_xml) do
          <<-EOF.strip_heredoc
          <rightsMetadata>
            <access type="read">
              <machine>
                <group rule="no-download">Stanford</group>
              </machine>
            </access>
          </rightsMetadata>
          EOF
        end
        it { is_expected.not_to be_able_to(:download, file) }
        it { is_expected.not_to be_able_to(:download, image) }
        it { is_expected.not_to be_able_to(:download, media) }
        it { is_expected.not_to be_able_to(:read, file) }
        it { is_expected.not_to be_able_to(:read, image) }
        it { is_expected.not_to be_able_to(:read, media) }
        it { is_expected.to be_able_to(:read, tile) }
        it { is_expected.to be_able_to(:stream, media) }
        it { is_expected.to be_able_to(:access, file) }
        it { is_expected.to be_able_to(:read_metadata, image) }
        it { is_expected.to be_able_to(:read, thumbnail) }
        it { is_expected.to be_able_to(:read, square_thumbnail) }
      end

      context 'with a file with no read access' do
        let(:rights_xml) do
          <<-EOF.strip_heredoc
          <rightsMetadata>
            <access type="read">
              <machine>
                <none/>
              </machine>
            </access>
          </rightsMetadata>
          EOF
        end
        it { is_expected.not_to be_able_to(:download, file) }
        it { is_expected.not_to be_able_to(:download, image) }
        it { is_expected.not_to be_able_to(:download, media) }
        it { is_expected.not_to be_able_to(:read, file) }
        it { is_expected.not_to be_able_to(:read, image) }
        it { is_expected.not_to be_able_to(:read, media) }
        it { is_expected.not_to be_able_to(:read, tile) }
        it { is_expected.not_to be_able_to(:stream, media) }
        it { is_expected.not_to be_able_to(:access, file) }
        it { is_expected.to be_able_to(:read_metadata, image) }
        it { is_expected.to be_able_to(:read, thumbnail) }
        it { is_expected.to be_able_to(:read, square_thumbnail) }
      end
    end

    context 'for a non-stanford webauth user' do
      let(:user) { User.new(id: 'a', webauth_user: true, ldap_groups: %w(stanford:sponsored)) }

      context 'with a world-readable file' do
        let(:rights_xml) do
          <<-EOF.strip_heredoc
          <rightsMetadata>
              <access type="read">
                <machine>
                  <world/>
                </machine>
              </access>
            </rightsMetadata>
          EOF
        end
        it { is_expected.to be_able_to(:download, file) }
        it { is_expected.to be_able_to(:download, image) }
        it { is_expected.to be_able_to(:download, media) }
        it { is_expected.to be_able_to(:read, file) }
        it { is_expected.to be_able_to(:read, image) }
        it { is_expected.to be_able_to(:read, media) }
        it { is_expected.to be_able_to(:read, tile) }
        it { is_expected.to be_able_to(:stream, media) }
        it { is_expected.to be_able_to(:access, file) }
        it { is_expected.to be_able_to(:read_metadata, image) }
        it { is_expected.to be_able_to(:read, thumbnail) }
        it { is_expected.to be_able_to(:read, square_thumbnail) }
      end

      context 'with a stanford-only file' do
        let(:rights_xml) do
          <<-EOF.strip_heredoc
          <rightsMetadata>
            <access type="read">
              <machine>
                <group>Stanford</group>
              </machine>
            </access>
          </rightsMetadata>
          EOF
        end
        it { is_expected.not_to be_able_to(:download, file) }
        it { is_expected.not_to be_able_to(:download, image) }
        it { is_expected.not_to be_able_to(:download, media) }
        it { is_expected.not_to be_able_to(:read, file) }
        it { is_expected.not_to be_able_to(:read, image) }
        it { is_expected.not_to be_able_to(:read, media) }
        it { is_expected.not_to be_able_to(:read, tile) }
        it { is_expected.not_to be_able_to(:stream, media) }
        it { is_expected.not_to be_able_to(:access, file) }
        it { is_expected.to be_able_to(:read_metadata, image) }
        it { is_expected.to be_able_to(:read, thumbnail) }
        it { is_expected.to be_able_to(:read, square_thumbnail) }
      end

      context 'with read rights but not download' do
        let(:rights_xml) do
          <<-EOF.strip_heredoc
          <rightsMetadata>
            <access type="read">
              <machine>
                <group rule="no-download">Stanford</group>
              </machine>
            </access>
          </rightsMetadata>
          EOF
        end
        it { is_expected.not_to be_able_to(:download, file) }
        it { is_expected.not_to be_able_to(:download, image) }
        it { is_expected.not_to be_able_to(:download, media) }
        it { is_expected.not_to be_able_to(:read, file) }
        it { is_expected.not_to be_able_to(:read, image) }
        it { is_expected.not_to be_able_to(:read, media) }
        it { is_expected.not_to be_able_to(:read, tile) }
        it { is_expected.not_to be_able_to(:stream, media) }
        it { is_expected.not_to be_able_to(:access, file) }
        it { is_expected.to be_able_to(:read_metadata, image) }
        it { is_expected.to be_able_to(:read, thumbnail) }
        it { is_expected.to be_able_to(:read, square_thumbnail) }
      end
    end

    context 'for location-based access restrictions' do
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
      context 'with an anonymous user from a configured location' do
        let(:user) { User.new(ip_address: 'ip.address2') }
        it { is_expected.to be_able_to(:download, file) }
        it { is_expected.to be_able_to(:download, image) }
        it { is_expected.to be_able_to(:download, media) }
        it { is_expected.to be_able_to(:read, file) }
        it { is_expected.to be_able_to(:read, image) }
        it { is_expected.to be_able_to(:read, media) }
        it { is_expected.to be_able_to(:read, tile) }
        it { is_expected.to be_able_to(:stream, media) }
        it { is_expected.to be_able_to(:access, file) }
        it { is_expected.to be_able_to(:read_metadata, image) }
        it { is_expected.to be_able_to(:read, thumbnail) }
        it { is_expected.to be_able_to(:read, square_thumbnail) }
      end

      context 'with an anonymous user not in the configured location' do
        let(:user) { User.new(ip_address: 'some.unknown.ip') }
        it { is_expected.not_to be_able_to(:download, file) }
        it { is_expected.not_to be_able_to(:download, image) }
        it { is_expected.not_to be_able_to(:download, media) }
        it { is_expected.not_to be_able_to(:read, file) }
        it { is_expected.not_to be_able_to(:read, image) }
        it { is_expected.not_to be_able_to(:read, media) }
        it { is_expected.not_to be_able_to(:read, tile) }
        it { is_expected.not_to be_able_to(:stream, media) }
        it { is_expected.not_to be_able_to(:access, file) }
        it { is_expected.to be_able_to(:read_metadata, image) }
        it { is_expected.to be_able_to(:read, thumbnail) }
        it { is_expected.to be_able_to(:read, square_thumbnail) }
      end

      context 'with media that allows read but not download' do
        let(:rights_xml) do
          <<-EOF.strip_heredoc
          <rightsMetadata>
            <access type="read">
              <machine>
                <location rule="no-download">location1</location>
              </machine>
            </access>
          </rightsMetadata>
          EOF
        end
        context 'for an anonymous user from a configured location' do
          let(:user) { User.new(ip_address: 'ip.address2') }
          it { is_expected.not_to be_able_to(:download, file) }
          it { is_expected.not_to be_able_to(:download, image) }
          it { is_expected.not_to be_able_to(:download, media) }
          it { is_expected.not_to be_able_to(:read, file) }
          it { is_expected.not_to be_able_to(:read, image) }
          it { is_expected.not_to be_able_to(:read, media) }
          it { is_expected.to be_able_to(:read, tile) }
          it { is_expected.to be_able_to(:stream, media) }
          it { is_expected.to be_able_to(:access, file) }
          it { is_expected.to be_able_to(:read_metadata, image) }
          it { is_expected.to be_able_to(:read, thumbnail) }
          it { is_expected.to be_able_to(:read, square_thumbnail) }
        end
        context 'for an anonymous user not in the configured location' do
          let(:user) { User.new(ip_address: 'some.unknown.ip') }
          it { is_expected.not_to be_able_to(:download, file) }
          it { is_expected.not_to be_able_to(:download, image) }
          it { is_expected.not_to be_able_to(:download, media) }
          it { is_expected.not_to be_able_to(:read, file) }
          it { is_expected.not_to be_able_to(:read, image) }
          it { is_expected.not_to be_able_to(:read, media) }
          it { is_expected.not_to be_able_to(:read, tile) }
          it { is_expected.not_to be_able_to(:stream, media) }
          it { is_expected.not_to be_able_to(:access, file) }
          it { is_expected.to be_able_to(:read_metadata, image) }
          it { is_expected.to be_able_to(:read, thumbnail) }
          it { is_expected.to be_able_to(:read, square_thumbnail) }
        end
      end
    end

    context 'for an app user' do
      let(:user) { User.new(id: 'a', app_user: true) }

      context 'with an unrestricted file' do
        let(:rights_xml) do
          <<-EOF.strip_heredoc
          <rightsMetadata>
              <access type="read">
                <machine>
                  <world />
                </machine>
              </access>
            </rightsMetadata>
          EOF
        end
        it { is_expected.to be_able_to(:download, file) }
        it { is_expected.to be_able_to(:download, image) }
        it { is_expected.to be_able_to(:download, media) }
        it { is_expected.to be_able_to(:read, file) }
        it { is_expected.to be_able_to(:read, image) }
        it { is_expected.to be_able_to(:read, media) }
        it { is_expected.to be_able_to(:read, tile) }
        it { is_expected.to be_able_to(:stream, media) }
        it { is_expected.to be_able_to(:access, file) }
        it { is_expected.to be_able_to(:read_metadata, image) }
        it { is_expected.to be_able_to(:read, thumbnail) }
        it { is_expected.to be_able_to(:read, square_thumbnail) }
      end

      context 'with a world-readable file that also has agent rights' do
        let(:rights_xml) do
          <<-EOF.strip_heredoc
          <rightsMetadata>
              <access type="read">
                <machine>
                  <world />
                  <agent>a</agent>
                </machine>
              </access>
            </rightsMetadata>
          EOF
        end
        it { is_expected.to be_able_to(:download, file) }
        it { is_expected.to be_able_to(:download, image) }
        it { is_expected.to be_able_to(:download, media) }
        it { is_expected.to be_able_to(:read, file) }
        it { is_expected.to be_able_to(:read, image) }
        it { is_expected.to be_able_to(:read, media) }
        it { is_expected.to be_able_to(:read, tile) }
        it { is_expected.to be_able_to(:stream, media) }
        it { is_expected.to be_able_to(:access, file) }
        it { is_expected.to be_able_to(:read_metadata, image) }
        it { is_expected.to be_able_to(:read, thumbnail) }
        it { is_expected.to be_able_to(:read, square_thumbnail) }
      end

      context 'with a stanford-restricted file that also has agent rights' do
        let(:rights_xml) do
          <<-EOF.strip_heredoc
          <rightsMetadata>
            <access type="read">
              <machine>
                <group>Stanford</group>
                <agent>a</agent>
              </machine>
            </access>
          </rightsMetadata>
          EOF
        end
        it { is_expected.to be_able_to(:download, file) }
        it { is_expected.to be_able_to(:download, image) }
        it { is_expected.to be_able_to(:download, media) }
        it { is_expected.to be_able_to(:read, file) }
        it { is_expected.to be_able_to(:read, image) }
        it { is_expected.to be_able_to(:read, media) }
        it { is_expected.to be_able_to(:read, tile) }
        it { is_expected.to be_able_to(:stream, media) }
        it { is_expected.to be_able_to(:access, file) }
        it { is_expected.to be_able_to(:read_metadata, image) }
        it { is_expected.to be_able_to(:read, thumbnail) }
        it { is_expected.to be_able_to(:read, square_thumbnail) }
      end

      context 'with an agent-only file' do
        let(:rights_xml) do
          <<-EOF.strip_heredoc
          <rightsMetadata>
            <access type="read">
              <machine>
                <agent>a</agent>
              </machine>
            </access>
          </rightsMetadata>
          EOF
        end
        it { is_expected.to be_able_to(:download, file) }
        it { is_expected.to be_able_to(:download, image) }
        it { is_expected.to be_able_to(:download, media) }
        it { is_expected.to be_able_to(:read, file) }
        it { is_expected.to be_able_to(:read, image) }
        it { is_expected.to be_able_to(:read, media) }
        it { is_expected.to be_able_to(:read, tile) }
        it { is_expected.to be_able_to(:stream, media) }
        it { is_expected.to be_able_to(:access, file) }
        it { is_expected.to be_able_to(:read_metadata, image) }
        it { is_expected.to be_able_to(:read, thumbnail) }
        it { is_expected.to be_able_to(:read, square_thumbnail) }
      end

      context 'with an agent-only file with a no-download rule' do
        let(:rights_xml) do
          <<-EOF.strip_heredoc
          <rightsMetadata>
            <access type="read">
              <machine>
                <agent rule="no-download">a</group>
              </machine>
            </access>
          </rightsMetadata>
          EOF
        end
        it { is_expected.not_to be_able_to(:download, file) }
        it { is_expected.not_to be_able_to(:download, image) }
        it { is_expected.not_to be_able_to(:download, media) }
        it { is_expected.not_to be_able_to(:read, file) }
        it { is_expected.not_to be_able_to(:read, image) }
        it { is_expected.not_to be_able_to(:read, media) }
        it { is_expected.to be_able_to(:read, tile) }
        it { is_expected.to be_able_to(:stream, media) }
        it { is_expected.to be_able_to(:access, file) }
        it { is_expected.to be_able_to(:read_metadata, image) }
        it { is_expected.to be_able_to(:read, thumbnail) }
        it { is_expected.to be_able_to(:read, square_thumbnail) }
      end
    end

    context 'for an anonymous user' do
      context 'with a world-readable file' do
        let(:rights_xml) do
          <<-EOF.strip_heredoc
          <rightsMetadata>
              <access type="read">
                <machine>
                  <world/>
                </machine>
              </access>
            </rightsMetadata>
          EOF
        end
        it { is_expected.to be_able_to(:download, file) }
        it { is_expected.to be_able_to(:download, image) }
        it { is_expected.to be_able_to(:download, media) }
        it { is_expected.to be_able_to(:read, file) }
        it { is_expected.to be_able_to(:read, image) }
        it { is_expected.to be_able_to(:read, media) }
        it { is_expected.to be_able_to(:read, tile) }
        it { is_expected.to be_able_to(:stream, media) }
        it { is_expected.to be_able_to(:access, file) }
        it { is_expected.to be_able_to(:read_metadata, image) }
        it { is_expected.to be_able_to(:read, thumbnail) }
        it { is_expected.to be_able_to(:read, square_thumbnail) }
      end

      context 'with a stanford-only file' do
        let(:rights_xml) do
          <<-EOF.strip_heredoc
          <rightsMetadata>
            <access type="read">
              <machine>
                <group>Stanford</group>
              </machine>
            </access>
          </rightsMetadata>
          EOF
        end
        it { is_expected.not_to be_able_to(:download, file) }
        it { is_expected.not_to be_able_to(:download, image) }
        it { is_expected.not_to be_able_to(:download, media) }
        it { is_expected.not_to be_able_to(:read, file) }
        it { is_expected.not_to be_able_to(:read, image) }
        it { is_expected.not_to be_able_to(:read, media) }
        it { is_expected.not_to be_able_to(:read, tile) }
        it { is_expected.not_to be_able_to(:stream, media) }
        it { is_expected.not_to be_able_to(:access, file) }
        it { is_expected.to be_able_to(:read_metadata, image) }
        it { is_expected.to be_able_to(:read, thumbnail) }
        it { is_expected.to be_able_to(:read, square_thumbnail) }
      end

      context 'with a an unreadable file' do
        let(:rights_xml) do
          <<-EOF.strip_heredoc
          <rightsMetadata>
            <access type="read">
              <machine>
                <none/>
              </machine>
            </access>
          </rightsMetadata>
          EOF
        end
        it { is_expected.not_to be_able_to(:download, file) }
        it { is_expected.not_to be_able_to(:download, image) }
        it { is_expected.not_to be_able_to(:download, media) }
        it { is_expected.not_to be_able_to(:read, file) }
        it { is_expected.not_to be_able_to(:read, image) }
        it { is_expected.not_to be_able_to(:read, media) }
        it { is_expected.not_to be_able_to(:read, tile) }
        it { is_expected.not_to be_able_to(:stream, media) }
        it { is_expected.not_to be_able_to(:access, file) }
        it { is_expected.to be_able_to(:read_metadata, image) }
        it { is_expected.to be_able_to(:read, thumbnail) }
        it { is_expected.to be_able_to(:read, square_thumbnail) }
      end

      context 'with read rights but not download' do
        let(:rights_xml) do
          <<-EOF.strip_heredoc
          <rightsMetadata>
            <access type="read">
              <machine>
                <world rule="no-download"/>
              </machine>
            </access>
          </rightsMetadata>
          EOF
        end
        it { is_expected.not_to be_able_to(:download, file) }
        it { is_expected.not_to be_able_to(:download, image) }
        it { is_expected.not_to be_able_to(:download, media) }
        it { is_expected.not_to be_able_to(:read, file) }
        it { is_expected.not_to be_able_to(:read, image) }
        it { is_expected.not_to be_able_to(:read, media) }
        it { is_expected.to be_able_to(:read, tile) }
        it { is_expected.to be_able_to(:stream, media) }
        it { is_expected.to be_able_to(:access, file) }
        it { is_expected.to be_able_to(:read_metadata, image) }
        it { is_expected.to be_able_to(:read, thumbnail) }
        it { is_expected.to be_able_to(:read, square_thumbnail) }
      end
    end

    describe 'for multiple read access declarations' do
      context 'with stanford read access and location based read access with download restriction' do
        let(:rights_xml) do
          <<-EOF.strip_heredoc
          <rightsMetadata>
            <access type="read">
              <machine>
                <group>Stanford</group>
              </machine>
              <machine>
                <location rule="no-download">location1</location>
              </machine>
            </access>
          </rightsMetadata>
          EOF
        end

        context 'for a stanford webauth user at an unknown location' do
          let(:user) { User.new(id: 'a', webauth_user: true, ldap_groups: %w(stanford:stanford)) }

          it { is_expected.to be_able_to(:download, file) }
          it { is_expected.to be_able_to(:download, image) }
          it { is_expected.to be_able_to(:download, media) }
          it { is_expected.to be_able_to(:read, file) }
          it { is_expected.to be_able_to(:read, image) }
          it { is_expected.to be_able_to(:read, media) }
          it { is_expected.to be_able_to(:read, tile) }
          it { is_expected.to be_able_to(:stream, media) }
          it { is_expected.to be_able_to(:access, file) }
          it { is_expected.to be_able_to(:read_metadata, image) }
          it { is_expected.to be_able_to(:read, thumbnail) }
          it { is_expected.to be_able_to(:read, square_thumbnail) }
        end

        context 'for an anonymous user from a configured location' do
          let(:user) { User.new(ip_address: 'ip.address1') }

          it { is_expected.not_to be_able_to(:download, file) }
          it { is_expected.not_to be_able_to(:download, image) }
          it { is_expected.not_to be_able_to(:download, media) }
          it { is_expected.not_to be_able_to(:read, file) }
          it { is_expected.not_to be_able_to(:read, image) }
          it { is_expected.not_to be_able_to(:read, media) }
          it { is_expected.to be_able_to(:read, tile) }
          it { is_expected.to be_able_to(:stream, media) }
          it { is_expected.to be_able_to(:access, file) }
          it { is_expected.to be_able_to(:read_metadata, image) }
          it { is_expected.to be_able_to(:read, thumbnail) }
          it { is_expected.to be_able_to(:read, square_thumbnail) }
        end

        context 'for a stanford webauth user from a configured location' do
          let(:user) do
            User.new(id: 'a', webauth_user: true, ldap_groups: %w(stanford:stanford), ip_address: 'ip.address1')
          end

          it { is_expected.to be_able_to(:download, file) }
          it { is_expected.to be_able_to(:download, image) }
          it { is_expected.to be_able_to(:download, media) }
          it { is_expected.to be_able_to(:read, file) }
          it { is_expected.to be_able_to(:read, image) }
          it { is_expected.to be_able_to(:read, media) }
          it { is_expected.to be_able_to(:read, tile) }
          it { is_expected.to be_able_to(:stream, media) }
          it { is_expected.to be_able_to(:access, file) }
          it { is_expected.to be_able_to(:read_metadata, image) }
          it { is_expected.to be_able_to(:read, thumbnail) }
          it { is_expected.to be_able_to(:read, square_thumbnail) }
        end

        context 'for a non-stanford webauth user from a configured location' do
          let(:user) do
            User.new(id: 'a', webauth_user: true, ldap_groups: %w(stanford:sponsored), ip_address: 'ip.address1')
          end

          it { is_expected.not_to be_able_to(:download, file) }
          it { is_expected.not_to be_able_to(:download, image) }
          it { is_expected.not_to be_able_to(:download, media) }
          it { is_expected.not_to be_able_to(:read, file) }
          it { is_expected.not_to be_able_to(:read, image) }
          it { is_expected.not_to be_able_to(:read, media) }
          it { is_expected.to be_able_to(:read, tile) }
          it { is_expected.to be_able_to(:stream, media) }
          it { is_expected.to be_able_to(:access, file) }
          it { is_expected.to be_able_to(:read_metadata, image) }
          it { is_expected.to be_able_to(:read, thumbnail) }
          it { is_expected.to be_able_to(:read, square_thumbnail) }
        end

        context 'for a non-stanford webauth user from an unknown location' do
          let(:user) do
            User.new(id: 'a', webauth_user: true, ldap_groups: %w(stanford:sponsored), ip_address: 'another.unknown.ip')
          end

          it { is_expected.not_to be_able_to(:download, file) }
          it { is_expected.not_to be_able_to(:download, image) }
          it { is_expected.not_to be_able_to(:download, media) }
          it { is_expected.not_to be_able_to(:read, file) }
          it { is_expected.not_to be_able_to(:read, image) }
          it { is_expected.not_to be_able_to(:read, media) }
          it { is_expected.not_to be_able_to(:read, tile) }
          it { is_expected.not_to be_able_to(:stream, media) }
          it { is_expected.not_to be_able_to(:access, file) }
          it { is_expected.to be_able_to(:read_metadata, image) }
          it { is_expected.to be_able_to(:read, thumbnail) }
          it { is_expected.to be_able_to(:read, square_thumbnail) }
        end
      end

      context 'with two locations configured for read access, including one with a no-download rule' do
        let(:rights_xml) do
          <<-EOF.strip_heredoc
          <rightsMetadata>
            <access type="read">
              <machine>
                <location rule="no-download">location1</location>
              </machine>
              <machine>
                <location>location2</location>
              </machine>
            </access>
          </rightsMetadata>
          EOF
        end

        context 'for an anonymous user user from the first configured location' do
          let(:user) { User.new(ip_address: 'ip.address2') }

          it { is_expected.not_to be_able_to(:download, file) }
          it { is_expected.not_to be_able_to(:download, image) }
          it { is_expected.not_to be_able_to(:download, media) }
          it { is_expected.not_to be_able_to(:read, file) }
          it { is_expected.not_to be_able_to(:read, image) }
          it { is_expected.not_to be_able_to(:read, media) }
          it { is_expected.to be_able_to(:read, tile) }
          it { is_expected.to be_able_to(:stream, media) }
          it { is_expected.to be_able_to(:access, file) }
          it { is_expected.to be_able_to(:read_metadata, image) }
          it { is_expected.to be_able_to(:read, thumbnail) }
          it { is_expected.to be_able_to(:read, square_thumbnail) }
        end

        context 'for an anonymous user user from the second configured location' do
          let(:user) { User.new(ip_address: 'ip.address4') }

          it { is_expected.to be_able_to(:download, file) }
          it { is_expected.to be_able_to(:download, image) }
          it { is_expected.to be_able_to(:download, media) }
          it { is_expected.to be_able_to(:read, file) }
          it { is_expected.to be_able_to(:read, image) }
          it { is_expected.to be_able_to(:read, media) }
          it { is_expected.to be_able_to(:read, tile) }
          it { is_expected.to be_able_to(:stream, media) }
          it { is_expected.to be_able_to(:access, file) }
          it { is_expected.to be_able_to(:read_metadata, image) }
          it { is_expected.to be_able_to(:read, thumbnail) }
          it { is_expected.to be_able_to(:read, square_thumbnail) }
        end

        context 'for an anonymous user user from an unrecognized location' do
          let(:user) { User.new(ip_address: 'another.unknown.ip') }

          it { is_expected.not_to be_able_to(:download, file) }
          it { is_expected.not_to be_able_to(:download, image) }
          it { is_expected.not_to be_able_to(:download, media) }
          it { is_expected.not_to be_able_to(:read, file) }
          it { is_expected.not_to be_able_to(:read, image) }
          it { is_expected.not_to be_able_to(:read, media) }
          it { is_expected.not_to be_able_to(:read, tile) }
          it { is_expected.not_to be_able_to(:stream, media) }
          it { is_expected.not_to be_able_to(:access, file) }
          it { is_expected.to be_able_to(:read_metadata, image) }
          it { is_expected.to be_able_to(:read, thumbnail) }
          it { is_expected.to be_able_to(:read, square_thumbnail) }
        end
      end

      context 'with world (no-download), and full access for stanford users' do
        let(:rights_xml) do
          <<-EOF.strip_heredoc
          <rightsMetadata>
            <access type="read">
              <machine>
                <world rule="no-download"/>
              </machine>
              <machine>
                <group>Stanford</group>
              </machine>
            </access>
          </rightsMetadata>
          EOF
        end

        context 'for an anonymous user' do
          it { is_expected.not_to be_able_to(:download, file) }
          it { is_expected.not_to be_able_to(:download, image) }
          it { is_expected.not_to be_able_to(:download, media) }
          it { is_expected.not_to be_able_to(:read, file) }
          it { is_expected.not_to be_able_to(:read, image) }
          it { is_expected.not_to be_able_to(:read, media) }
          it { is_expected.to be_able_to(:read, tile) }
          it { is_expected.to be_able_to(:stream, media) }
          it { is_expected.to be_able_to(:access, file) }
          it { is_expected.to be_able_to(:read_metadata, image) }
          it { is_expected.to be_able_to(:read, thumbnail) }
          it { is_expected.to be_able_to(:read, square_thumbnail) }
        end

        context 'for a stanford webauth user' do
          let(:user) { User.new(id: 'a', webauth_user: true, ldap_groups: %w(stanford:stanford)) }

          it { is_expected.to be_able_to(:download, file) }
          it { is_expected.to be_able_to(:download, image) }
          it { is_expected.to be_able_to(:download, media) }
          it { is_expected.to be_able_to(:read, file) }
          it { is_expected.to be_able_to(:read, image) }
          it { is_expected.to be_able_to(:read, media) }
          it { is_expected.to be_able_to(:read, tile) }
          it { is_expected.to be_able_to(:stream, media) }
          it { is_expected.to be_able_to(:access, file) }
          it { is_expected.to be_able_to(:read_metadata, image) }
          it { is_expected.to be_able_to(:read, thumbnail) }
          it { is_expected.to be_able_to(:read, square_thumbnail) }
        end
      end
    end

    describe 'for objects with file specific rights' do
      context 'with an object that defaults to world, but restricts the video to no-download' do
        let(:rights_xml) do
          <<-EOF.strip_heredoc
          <rightsMetadata>
            <access type="read">
              <machine>
                <world/>
              </machine>
            </access>
            <access type="read">
              <file>movie.mp4</file>
              <machine>
                <world rule="no-download"/>
              </machine>
            </access>
          </rightsMetadata>
          EOF
        end

        context 'as an anonymous user' do
          it { is_expected.to be_able_to(:download, file) }
          it { is_expected.to be_able_to(:download, image) }
          it { is_expected.not_to be_able_to(:download, media) }
          it { is_expected.to be_able_to(:read, file) }
          it { is_expected.to be_able_to(:read, image) }
          it { is_expected.not_to be_able_to(:read, media) }
          it { is_expected.to be_able_to(:read, tile) }
          it { is_expected.to be_able_to(:stream, media) }
          it { is_expected.to be_able_to(:access, file) }
          it { is_expected.to be_able_to(:access, media) }
          it { is_expected.to be_able_to(:read_metadata, image) }
          it { is_expected.to be_able_to(:read, thumbnail) }
          it { is_expected.to be_able_to(:read, square_thumbnail) }
        end
      end

      context 'with an object that defaults to stanford, but restricts the image to location1' do
        let(:rights_xml) do
          <<-EOF.strip_heredoc
          <rightsMetadata>
            <access type="read">
              <machine>
                <group>Stanford</group>
              </machine>
            </access>
            <access type="read">
              <file>image.jpg</file>
              <machine>
                <location>location1</location>
              </machine>
            </access>
          </rightsMetadata>
          EOF
        end

        context 'as a stanford webauth user' do
          let(:user) { User.new(id: 'a', webauth_user: true, ldap_groups: %w(stanford:stanford)) }

          it { is_expected.to be_able_to(:download, file) }
          it { is_expected.not_to be_able_to(:download, image) }
          it { is_expected.to be_able_to(:download, media) }
          it { is_expected.to be_able_to(:read, file) }
          it { is_expected.not_to be_able_to(:read, image) }
          it { is_expected.to be_able_to(:read, media) }
          it { is_expected.to be_able_to(:read, tile) }
          it { is_expected.to be_able_to(:stream, media) }
          it { is_expected.to be_able_to(:access, file) }
          it { is_expected.not_to be_able_to(:access, image) }
          it { is_expected.to be_able_to(:read_metadata, image) }
          it { is_expected.to be_able_to(:read, thumbnail) }
          it { is_expected.to be_able_to(:read, square_thumbnail) }
        end

        context 'as a stanford webauth user in location1' do
          let(:user) do
            User.new(id: 'a', webauth_user: true, ldap_groups: %w(stanford:stanford), ip_address: 'ip.address1')
          end

          it { is_expected.to be_able_to(:download, file) }
          it { is_expected.to be_able_to(:download, image) }
          it { is_expected.to be_able_to(:download, media) }
          it { is_expected.to be_able_to(:read, file) }
          it { is_expected.to be_able_to(:read, image) }
          it { is_expected.to be_able_to(:read, media) }
          it { is_expected.to be_able_to(:read, tile) }
          it { is_expected.to be_able_to(:stream, media) }
          it { is_expected.to be_able_to(:access, file) }
          it { is_expected.to be_able_to(:access, image) }
          it { is_expected.to be_able_to(:read_metadata, image) }
          it { is_expected.to be_able_to(:read, thumbnail) }
          it { is_expected.to be_able_to(:read, square_thumbnail) }
        end

        context 'as an anonymous user' do
          it { is_expected.not_to be_able_to(:download, file) }
          it { is_expected.not_to be_able_to(:download, image) }
          it { is_expected.not_to be_able_to(:download, media) }
          it { is_expected.not_to be_able_to(:read, file) }
          it { is_expected.not_to be_able_to(:read, image) }
          it { is_expected.not_to be_able_to(:read, media) }
          it { is_expected.not_to be_able_to(:read, tile) }
          it { is_expected.not_to be_able_to(:stream, media) }
          it { is_expected.not_to be_able_to(:access, file) }
          it { is_expected.not_to be_able_to(:access, image) }
          it { is_expected.to be_able_to(:read_metadata, image) }
          it { is_expected.to be_able_to(:read, thumbnail) }
          it { is_expected.to be_able_to(:read, square_thumbnail) }
        end
      end

      context 'with an object defaults to read access from location2, but file is agent-only' do
        let(:rights_xml) do
          <<-EOF.strip_heredoc
          <rightsMetadata>
            <access type="read">
              <machine>
                <location>location2</location>
              </machine>
            </access>
            <access type="read">
              <file>file.csv</file>
              <machine>
                <agent>a</agent>
              </machine>
            </access>
          </rightsMetadata>
          EOF
        end

        context 'as an anonymous user in location2' do
          let(:user) { User.new(ip_address: 'ip.address3') }

          it { is_expected.not_to be_able_to(:download, file) }
          it { is_expected.to be_able_to(:download, image) }
          it { is_expected.to be_able_to(:download, media) }
          it { is_expected.not_to be_able_to(:read, file) }
          it { is_expected.to be_able_to(:read, image) }
          it { is_expected.to be_able_to(:read, media) }
          it { is_expected.to be_able_to(:read, tile) }
          it { is_expected.to be_able_to(:stream, media) }
          it { is_expected.not_to be_able_to(:access, file) }
          it { is_expected.to be_able_to(:read_metadata, image) }
          it { is_expected.to be_able_to(:read, thumbnail) }
          it { is_expected.to be_able_to(:read, square_thumbnail) }
        end

        context 'as a stanford webauth user' do
          let(:user) { User.new(id: 'a', webauth_user: true, ldap_groups: %w(stanford:stanford)) }

          it { is_expected.not_to be_able_to(:download, file) }
          it { is_expected.not_to be_able_to(:download, image) }
          it { is_expected.not_to be_able_to(:download, media) }
          it { is_expected.not_to be_able_to(:read, file) }
          it { is_expected.not_to be_able_to(:read, image) }
          it { is_expected.not_to be_able_to(:read, media) }
          it { is_expected.not_to be_able_to(:read, tile) }
          it { is_expected.not_to be_able_to(:stream, media) }
          it { is_expected.not_to be_able_to(:access, file) }
          it { is_expected.to be_able_to(:read_metadata, image) }
          it { is_expected.to be_able_to(:read, thumbnail) }
          it { is_expected.to be_able_to(:read, square_thumbnail) }
        end

        context 'as an app user' do
          let(:user) { User.new(id: 'a', app_user: true) }

          it { is_expected.to be_able_to(:download, file) }
          it { is_expected.not_to be_able_to(:download, image) }
          it { is_expected.not_to be_able_to(:download, media) }
          it { is_expected.to be_able_to(:read, file) }
          it { is_expected.not_to be_able_to(:read, image) }
          it { is_expected.not_to be_able_to(:read, media) }
          it { is_expected.not_to be_able_to(:read, tile) }
          it { is_expected.not_to be_able_to(:stream, media) }
          it { is_expected.to be_able_to(:access, file) }
          it { is_expected.to be_able_to(:read_metadata, image) }
          it { is_expected.to be_able_to(:read, thumbnail) }
          it { is_expected.to be_able_to(:read, square_thumbnail) }
        end
      end
    end
  end

  describe '#stanford?' do
    context 'with a webauth user in the appropriate workgroups' do
      it 'is a stanford user' do
        expect(User.new(webauth_user: true, ldap_groups: %w(stanford:stanford))).to be_stanford
      end
    end

    context 'with just a webauth user' do
      it 'is not a stanford user' do
        expect(User.new(webauth_user: true, ldap_groups: %w(stanford:sponsored))).not_to be_stanford
      end
    end
  end

  describe '#token' do
    it 'is a value' do
      expect(subject.token).not_to be_blank
    end
  end

  describe '#location' do
    it 'is the string representation of the ApprovedLocation' do
      expect(User.new(ip_address: 'ip.address1').location).to eq 'location1'
    end
  end
end
