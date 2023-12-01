# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ObjectController do
  render_views

  before do
    allow_any_instance_of(StacksFile).to receive(:path).and_return(Rails.root + 'Gemfile')
  end

  describe '#show' do
    context 'when not logged in' do
      context "with an invalid druid" do
        let(:druid) { 'foo' }

        it 'returns a 404 Not Found' do
          allow(Faraday).to receive(:get).with('https://purl.stanford.edu/foo.xml').and_return(
            instance_double(Faraday::Response, status: 404, success?: false)
          )
          allow(Faraday).to receive(:get).with('https://purl.stanford.edu/foo.json').and_return(
            instance_double(Faraday::Response, status: 404, success?: false)
          )
          get :show, params: { id: 'foo' }
          expect(response.status).to eq 404
        end
      end

      context "with downloadable files" do
        let(:xml) do
          <<-EOXML
          <publicObject id="druid:fd063dh3727" published="2019-12-19T17:58:11Z" publishVersion="dor-services/8.1.1">
            <contentMetadata objectId="druid:fd063dh3727" type="book">
              <resource id="fd063dh3727_1" sequence="1" type="page">
                <label>Page 1</label>
                <file id="36105116040556_0002.pdf" mimetype="application/pdf" size="191643"></file>
                <file id="36105116040556_0002.xml" role="transcription" mimetype="application/xml" size="4220"></file>
                <file id="36105116040556_0002.jp2" mimetype="image/jp2" size="744853">
                  <imageData width="1738" height="2266"/>
                </file>
              </resource>
              <resource id="fd063dh3727_2" sequence="2" type="page">
              <label>Page 2</label>
                <file id="36105116040556_0003.pdf" mimetype="application/pdf" size="21418"></file>
                <file id="36105116040556_0003.xml" role="transcription" mimetype="application/xml" size="1129"></file>
                <file id="36105116040556_0003.jp2" mimetype="image/jp2" size="418977">
                  <imageData width="1241" height="1954"/>
                </file>
              </resource>
            </contentMetadata>
            <rightsMetadata>
              <access type="discover">
                <machine>
                  <world/>
                </machine>
              </access>
              <access type="read">
                <machine>
                  <world/>
                </machine>
              </access>
            </rightsMetadata>
          </publicObject>
          EOXML
        end
        let(:json) do
          {
            'structural' => {
              'contains' => [
                {
                  'structural' => {
                    'contains' => [
                      {
                        'filename' => '36105116040556_0002.pdf',
                        'access' => {
                          'view' => 'world',
                          'download' => 'world'
                        }
                      },
                      {
                        'filename' => '36105116040556_0002.xml',
                        'access' => {
                          'view' => 'world',
                          'download' => 'world'
                        }
                      },
                      {
                        'filename' => '36105116040556_0002.jp2',
                        'access' => {
                          'view' => 'world',
                          'download' => 'world'
                        }
                      }
                    ]
                  }
                },
                {
                  'structural' => {
                    'contains' => [
                      {
                        'filename' => '36105116040556_0003.pdf',
                        'access' => {
                          'view' => 'world',
                          'download' => 'world'
                        }
                      },
                      {
                        'filename' => '36105116040556_0003.xml',
                        'access' => {
                          'view' => 'world',
                          'download' => 'world'
                        }
                      },
                      {
                        'filename' => '36105116040556_0003.jp2',
                        'access' => {
                          'view' => 'world',
                          'download' => 'world'
                        }
                      }
                    ]
                  }
                }
              ]
            }
          }.to_json
        end

        before do
          allow(Faraday).to receive(:get).with('https://purl.stanford.edu/fd063dh3727.xml')
                                         .and_return(instance_double(Faraday::Response, success?: true, body: xml))
          allow(Faraday).to receive(:get).with('https://purl.stanford.edu/fd063dh3727.json')
                                         .and_return(instance_double(Faraday::Response, success?: true, body: json))
        end

        it 'creates a zip' do
          get :show, params: { id: 'fd063dh3727' }
          entries = ZipTricks::FileReader.new.read_zip_structure(io: StringIO.new(response.body))
          expect(entries.length).to eq 6
        end

        context 'when metrics tracking is enabled' do
          before do
            allow(Settings.features).to receive(:metrics).and_return(true)
            stub_request :post, 'https://sdr-metrics-api-prod.stanford.edu/ahoy/events'
            stub_request :post, 'https://sdr-metrics-api-prod.stanford.edu/ahoy/visits'
          end

          it 'tracks a download event with the druid' do
            get :show, params: { id: 'fd063dh3727' }
            expect(a_request(:post, 'https://sdr-metrics-api-prod.stanford.edu/ahoy/events').with do |req|
              expect(req.body).to include '"name":"download"'
              expect(req.body).to include '"druid":"fd063dh3727"'
            end).to have_been_made
          end
        end
      end

      context "with a stanford access file" do
        let(:xml) do
          <<-EOXML
            <publicObject id="druid:bb142ws0723" published="2020-05-09T00:44:17Z" publishVersion="dor-services/9.3.0">
              <contentMetadata objectId="bb142ws0723" type="media">
                <resource sequence="1" id="bb142ws0723_1" type="video">
                  <label>Video file 1</label>
                  <file id="bb142ws0723_01_sl.mp4" size="256265102" mimetype="video/mp4"> </file>
                  <file id="bb142ws0723_01_thumb.jp2" size="740541" mimetype="image/jp2">
                    <imageData width="1280" height="720"/>
                  </file>
                </resource>
                <resource sequence="9" id="bb142ws0723_9" type="file">
                  <label>Program</label>
                  <file id="bb142ws0723_program.pdf" size="991048" mimetype="application/pdf"> </file>
                </resource>
              </contentMetadata>
              <rightsMetadata>
                <access type="discover">
                  <machine>
                    <world/>
                  </machine>
                </access>
                <access type="read">
                  <machine>
                    <group>stanford</group>
                  </machine>
                </access>
                <access type="read">
                  <file>bb142ws0723_program.pdf</file>
                  <machine>
                    <world/>
                  </machine>
                </access>
              </rightsMetadata>
            </publicObject>
          EOXML
        end

        let(:json) do
          {
            'structural' => {
              'contains' => [
                {
                  'structural' => {
                    'contains' => [
                      {
                        'filename' => 'bb142ws0723_01_sl.mp4',
                        'access' => {
                          'view' => 'stanford',
                          'download' => 'stanford'
                        }
                      },
                      {
                        'filename' => 'bb142ws0723_01_thumb.jp2',
                        'access' => {
                          'view' => 'stanford',
                          'download' => 'stanford'
                        }
                      }
                    ]
                  }
                },
                {
                  'structural' => {
                    'contains' => [
                      {
                        'filename' => 'bb142ws0723_program.pdf',
                        'access' => {
                          'view' => 'world',
                          'download' => 'world'
                        }
                      }
                    ]
                  }
                }
              ]
            }
          }.to_json
        end

        before do
          allow(Faraday).to receive(:get).with('https://purl.stanford.edu/bb142ws0723.xml')
                                         .and_return(instance_double(Faraday::Response, success?: true, body: xml))
          allow(Faraday).to receive(:get).with('https://purl.stanford.edu/bb142ws0723.json')
                                         .and_return(instance_double(Faraday::Response, success?: true, body: json))
        end

        it 'redirects to login' do
          get :show, params: { id: 'bb142ws0723' }
          expect(response).to have_http_status(:found)
          expect(response.headers['Location']).to eq(auth_object_url(id: 'bb142ws0723'))
        end
      end
    end

    context 'when logged in as a stanford user' do
      let(:user) { User.new(webauth_user: true, ldap_groups: %w[stanford:stanford]) }

      before do
        allow_any_instance_of(described_class).to receive(:current_user).and_return(user)
      end

      context "with a stanford access file" do
        let(:xml) do
          <<-EOXML
            <publicObject id="druid:bb142ws0723" published="2020-05-09T00:44:17Z" publishVersion="dor-services/9.3.0">
              <contentMetadata objectId="bb142ws0723" type="media">
                <resource sequence="1" id="bb142ws0723_1" type="video">
                  <label>Video file 1</label>
                  <file id="bb142ws0723_01_sl.mp4" size="256265102" mimetype="video/mp4"> </file>
                  <file id="bb142ws0723_01_thumb.jp2" size="740541" mimetype="image/jp2">
                    <imageData width="1280" height="720"/>
                  </file>
                </resource>
                <resource sequence="9" id="bb142ws0723_9" type="file">
                  <label>Program</label>
                  <file id="bb142ws0723_program.pdf" size="991048" mimetype="application/pdf"> </file>
                </resource>
              </contentMetadata>
              <rightsMetadata>
                <access type="discover">
                  <machine>
                    <world/>
                  </machine>
                </access>
                <access type="read">
                  <machine>
                    <group>stanford</group>
                  </machine>
                </access>
                <access type="read">
                  <file>bb142ws0723_program.pdf</file>
                  <machine>
                    <world/>
                  </machine>
                </access>
              </rightsMetadata>
            </publicObject>
          EOXML
        end
        let(:json) do
          {
            'structural' => {
              'contains' => [
                {
                  'structural' => {
                    'contains' => [
                      {
                        'filename' => 'bb142ws0723_01_sl.mp4',
                        'access' => {
                          'view' => 'stanford',
                          'download' => 'stanford'
                        }
                      },
                      {
                        'filename' => 'bb142ws0723_01_thumb.jp2',
                        'access' => {
                          'view' => 'stanford',
                          'download' => 'stanford'
                        }
                      }
                    ]
                  }
                },
                {
                  'structural' => {
                    'contains' => [
                      {
                        'filename' => 'bb142ws0723_program.pdf',
                        'access' => {
                          'view' => 'world',
                          'download' => 'world'
                        }
                      }
                    ]
                  }
                }
              ]
            }
          }.to_json
        end

        before do
          allow(Faraday).to receive(:get).with('https://purl.stanford.edu/bb142ws0723.xml')
                                         .and_return(instance_double(Faraday::Response, success?: true, body: xml))
          allow(Faraday).to receive(:get).with('https://purl.stanford.edu/bb142ws0723.json')
                                         .and_return(instance_double(Faraday::Response, success?: true, body: json))
        end

        it 'creates a zip' do
          get :show, params: { id: 'bb142ws0723' }
          entries = ZipTricks::FileReader.new.read_zip_structure(io: StringIO.new(response.body))
          expect(entries.length).to eq 3
        end
      end
    end
  end
end
