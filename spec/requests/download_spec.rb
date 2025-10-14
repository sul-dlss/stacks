# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Downloading an object' do
  let(:connection) { instance_double(Faraday::Connection) }

  before do
    allow_any_instance_of(StacksFile).to receive(:s3_key).and_return('bb/000/cr/7262/bb000cr7262/content/8ff299eda08d7c506273840d52a03bf3')
  end

  context 'when not logged in' do
    context "with an invalid druid" do
      let(:druid) { 'foo' }

      it 'returns a 404 Not Found' do
        allow(Faraday).to receive(:new).with(hash_including(url: 'https://purl.stanford.edu/foo.json')).and_return(connection)
        allow(connection).to receive(:get).and_return(
          instance_double(Faraday::Response, status: 404, success?: false)
        )
        get '/object/foo'
        expect(response).to have_http_status :not_found
      end
    end

    context "with downloadable files" do
      let(:json) do
        {
          'externalIdentifier' => 'druid:fd063dh3727',
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
                      },
                      "hasMessageDigests" => [
                        {
                          "type" => "sha1",
                          "digest" => "aca42a32c00df5eadca47d01eabed4dad4768329"
                        },
                        {
                          "type" => "md5",
                          "digest" => "fdcb37ed3daeef288ce9b512cada6ded"
                        }
                      ]
                    },
                    {
                      'filename' => '36105116040556_0002.xml',
                      'access' => {
                        'view' => 'world',
                        'download' => 'world'
                      },
                      "hasMessageDigests" => [
                        {
                          "type" => "sha1",
                          "digest" => "39a893f0592708ea39bb8a3321f7ab3185b86c42"
                        },
                        {
                          "type" => "md5",
                          "digest" => "bae4ac9f1a8aba1482bfb5f937338391"
                        }
                      ]
                    },
                    {
                      'filename' => '36105116040556_0002.jp2',
                      'access' => {
                        'view' => 'world',
                        'download' => 'world'
                      },
                      "hasMessageDigests" => [
                        {
                          "type" => "sha1",
                          "digest" => "4285af92179f807a5f41a1d615c9fafd705097ac"
                        },
                        {
                          "type" => "md5",
                          "digest" => "3b8ecfb3b5a5ec9bfcfb9d85b88394bc"
                        }
                      ]
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
                      },
                      "hasMessageDigests" => [
                        {
                          "type" => "sha1",
                          "digest" => "a8e9a51ef67c8bdeec28270b3bd1563b9c830448"
                        },
                        {
                          "type" => "md5",
                          "digest" => "a9270cbc4e5b96d3bd16ad00767632a5"
                        }
                      ]
                    },
                    {
                      'filename' => '36105116040556_0003.xml',
                      'access' => {
                        'view' => 'world',
                        'download' => 'world'
                      },
                      "hasMessageDigests" => [
                        {
                          "type" => "sha1",
                          "digest" => "adfb92fe77712cfeab137e040040753b8de6af7e"
                        },
                        {
                          "type" => "md5",
                          "digest" => "cb91c2874bc066f521dafb82ee55a0c8"
                        }
                      ]
                    },
                    {
                      'filename' => '36105116040556_0003.jp2',
                      'access' => {
                        'view' => 'world',
                        'download' => 'world'
                      },
                      "hasMessageDigests" => [
                        {
                          "type" => "sha1",
                          "digest" => "76c17fab28eeb58c4763a790a28eea3e65659582"
                        },
                        {
                          "type" => "md5",
                          "digest" => "ef4ecbc6b55cc6beb93857ff423b6930"
                        }
                      ]
                    }
                  ]
                }
              }
            ]
          }
        }.to_json
      end

      before do
        allow(Faraday).to receive(:new).with(hash_including(url: 'https://purl.stanford.edu/fd063dh3727.json')).and_return(connection)
        allow(connection).to receive(:get).and_return(
          instance_double(Faraday::Response, success?: true, body: json)
        )
      end

      it 'creates a zip' do
        get '/object/fd063dh3727'

        entries = ZipKit::FileReader.new.read_zip_structure(io: StringIO.new(response.body))
        expect(entries.length).to eq 6
      end
    end

    context "with a stanford access file" do
      let(:json) do
        {
          'externalIdentifier' => "druid:bb142ws0723",
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
        allow(Faraday).to receive(:new).with(hash_including(url: 'https://purl.stanford.edu/bb142ws0723.json')).and_return(connection)
        allow(connection).to receive(:get).and_return(instance_double(Faraday::Response, success?: true, body: json))
      end

      it 'redirects to login' do
        get '/object/bb142ws0723'

        expect(response).to have_http_status(:found)
        expect(response.headers['Location']).to eq(auth_object_url(id: 'bb142ws0723'))
      end
    end
  end

  context 'when logged in as a stanford user' do
    let(:user) { User.new(webauth_user: true, ldap_groups: %w[stanford:stanford]) }

    before do
      allow_any_instance_of(ObjectController).to receive(:current_user).and_return(user)
    end

    context "with a stanford access file" do
      let(:json) do
        {
          'externalIdentifier' => "druid:bb142ws0723",
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
                      },
                      "hasMessageDigests" => [
                        {
                          "type" => "sha1",
                          "digest" => "b9174fd20be391b82b64981c92a58cb6865a7089"
                        },
                        {
                          "type" => "md5",
                          "digest" => "edcd7c37acde6f64a4e6a2735f478daf"
                        }
                      ]
                    },
                    {
                      'filename' => 'bb142ws0723_01_thumb.jp2',
                      'access' => {
                        'view' => 'stanford',
                        'download' => 'stanford'
                      },
                      "hasMessageDigests" => [
                        {
                          "type" => "sha1",
                          "digest" => "05089813ddf83f70bf059eaf321bf53e0ec55f66"
                        },
                        {
                          "type" => "md5",
                          "digest" => "13e25faa7061023648611ad10cc304cc"
                        }
                      ]
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
                      },
                      "hasMessageDigests" => [
                        {
                          "type" => "sha1",
                          "digest" => "bd6f715d3d086f102e9ed7fe2dc1ba2f78add828"
                        },
                        {
                          "type" => "md5",
                          "digest" => "be2d92be8f76906020e7918988bd26b2"
                        }
                      ]
                    }
                  ]
                }
              }
            ]
          }
        }.to_json
      end

      before do
        allow(Faraday).to receive(:new).with(hash_including(url: 'https://purl.stanford.edu/bb142ws0723.json')).and_return(connection)
        allow(connection).to receive(:get).and_return(instance_double(Faraday::Response, success?: true, body: json))
      end

      it 'creates a zip' do
        get '/object/bb142ws0723'

        entries = ZipKit::FileReader.new.read_zip_structure(io: StringIO.new(response.body))
        expect(entries.length).to eq 3
      end
    end
  end
end
