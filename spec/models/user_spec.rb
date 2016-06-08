require 'rails_helper'

describe User do
  describe 'abilities' do
    subject(:ability) { Ability.new(user) }
    let(:user) { nil }
    let(:file) { StacksFile.new.tap { |x| allow(x).to receive(:rights_xml).and_return(rights_xml) } }
    let(:image) { StacksImage.new.tap { |x| allow(x).to receive(:rights_xml).and_return(rights_xml) } }
    let(:thumbnail) { StacksImage.new(region: 'full', size: '!400,400') }
    let(:square_thumbnail) { StacksImage.new(region: 'square', size: '!400,400') }
    let(:tile) { StacksImage.new(region: '0,0,100,100', size: '256,256') }
    let(:media) { StacksMediaStream.new.tap { |x| allow(x).to receive(:rights_xml).and_return(rights_xml) } }
    let(:rights_xml) { '' }

    before do
      allow_any_instance_of(StacksImage).to receive(:rights_xml).and_return(rights_xml)
    end

    context 'stanford webauth user' do
      let(:user) { User.new(id: 'a', webauth_user: true, ldap_groups: %w(stanford:stanford)) }

      context 'with an unrestricted file' do
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
      end

      context 'with an world-readable file' do
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
      end

      context 'with an stanford-only file' do
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
      end

      context 'with a tile of a no-download file' do
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
        it { is_expected.to be_able_to(:read, tile) }
        it { is_expected.not_to be_able_to(:read, file) }
        it { is_expected.not_to be_able_to(:read, image) }
        it { is_expected.not_to be_able_to(:read, media) }
      end
    end

    context 'non-stanford webauth user' do
      let(:user) { User.new(id: 'a', webauth_user: true, ldap_groups: %w(stanford:sponsored)) }

      context 'with an unrestricted file' do
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
      end

      context 'with an world-readable file' do
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
      end

      context 'with an stanford-only file' do
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
      end

      context 'with a tile of a no-download file' do
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
        it { is_expected.not_to be_able_to(:read, tile) }
        it { is_expected.not_to be_able_to(:read, file) }
        it { is_expected.not_to be_able_to(:read, image) }
        it { is_expected.not_to be_able_to(:read, media) }
      end
    end

    context 'location based' do
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
      context 'an anonymous user from a configured location' do
        let(:user) { User.new(ip_address: 'ip.address2') }
        it { is_expected.to be_able_to(:download, file) }
        it { is_expected.to be_able_to(:download, image) }
        it { is_expected.to be_able_to(:download, media) }
      end

      context 'an anonymous user not in the configured location' do
        let(:user) { User.new(ip_address: 'some.unknown.ip') }
        it { is_expected.not_to be_able_to(:download, file) }
        it { is_expected.not_to be_able_to(:download, image) }
        it { is_expected.not_to be_able_to(:download, media) }
      end
    end

    context 'app user' do
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
      end

      context 'with an world-readable file' do
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
      end

      context 'with an stanford-only file' do
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
      end

      context 'with a tile of a no-download file' do
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
        it { is_expected.to be_able_to(:read, tile) }
        it { is_expected.not_to be_able_to(:read, file) }
        it { is_expected.not_to be_able_to(:read, image) }
        it { is_expected.not_to be_able_to(:read, media) }
      end
    end

    context 'anonymous user' do
      context 'with an stanford-only file' do
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
      end

      context 'with a thumbnail of an unreadable file' do
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

        it { is_expected.to be_able_to(:read, thumbnail) }
        it { is_expected.to be_able_to(:read, square_thumbnail) }
        it { is_expected.not_to be_able_to(:read, image) }
        it { is_expected.not_to be_able_to(:read, media) }
      end

      context 'with a tile of a no-download file' do
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
        it { is_expected.to be_able_to(:read, tile) }
        it { is_expected.not_to be_able_to(:read, file) }
        it { is_expected.not_to be_able_to(:read, image) }
        it { is_expected.not_to be_able_to(:read, media) }
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
