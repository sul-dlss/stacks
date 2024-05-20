# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Metrics tracking' do
  include ActiveJob::TestHelper

  let(:druid) { 'nr349ct7889' }
  let(:file_name) { 'image.jp2' }
  let(:xml) do
    <<-XML
    <publicObject id="druid:#{druid}" published="2019-12-19T17:58:11Z" publishVersion="dor-services/8.1.1">
      <contentMetadata objectId="druid:#{druid}" type="book">
        <resource id="#{druid}_1" sequence="1" type="page">
          <label>Page 1</label>
          <file id="#{file_name}" mimetype="image/jp2" size="744853">
            <imageData width="1738" height="2266"/>
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
    XML
  end
  let(:json) do
    {
      'structural' => {
        'contains' => [
          {
            'structural' => {
              'contains' => [
                {
                  'filename' => file_name,
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
  let(:ability) { instance_double(Ability, can?: true, authorize!: true) }

  before do
    allow(Ability).to receive(:new).and_return(ability)
    allow(CocinaAbility).to receive(:new).and_return(ability)
    stub_rights_xml(world_readable_rights_xml)
    stub_request(:post, 'https://example.com/ahoy/events')
    stub_request(:get, "https://purl.stanford.edu/#{druid}.xml").to_return(status: 200, body: xml)
    stub_request(:get, "https://purl.stanford.edu/#{druid}.json").to_return(status: 200, body: json)
  end

  context 'with an object' do
    let(:file) do
      instance_double(
        StacksFile,
        id: druid,
        file_name:,
        path: Rails.root.join('spec/fixtures/nr/349/ct/7889/image.jp2'),
        mtime: Time.zone.now
      )
    end

    before do
      allow(StacksFile).to receive(:new).and_return(file)
    end

    it 'tracks downloads' do
      get object_path(druid),
          headers: { 'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_6) AppleWebKit/537.36 (KHTML, like Gecko)' },
          env: { 'REMOTE_ADDR' => '73.235.188.148' }

      perform_enqueued_jobs

      expect(a_request(:post, 'https://example.com/ahoy/events').with do |req|
        expect(req.body).to include '"name":"download"'
        expect(req.body).to include "\"druid\":\"#{druid}\""
        expect(req.headers['User-Agent']).to eq 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_6) AppleWebKit/537.36 (KHTML, like Gecko)'
        expect(req.headers['X-Forwarded-For']).to eq '73.235.188.148'
      end).to have_been_made
    end
  end

  context 'with a file' do
    it 'tracks downloads' do
      get file_path(druid, file_name),
          headers: { 'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_6) AppleWebKit/537.36 (KHTML, like Gecko)' },
          env: { 'REMOTE_ADDR' => '73.235.188.148' }

      perform_enqueued_jobs

      expect(a_request(:post, 'https://example.com/ahoy/events').with do |req|
        expect(req.body).to include '"name":"download"'
        expect(req.body).to include "\"druid\":\"#{druid}\""
        expect(req.body).to include "\"file\":\"#{file_name}\""
        expect(req.headers['User-Agent']).to eq 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_6) AppleWebKit/537.36 (KHTML, like Gecko)'
        expect(req.headers['X-Forwarded-For']).to eq '73.235.188.148'
      end).to have_been_made
    end
  end

  context 'with a IIIF image' do
    let(:image) do
      instance_double(
        StacksImage,
        valid?: true,
        exist?: true,
        etag: nil,
        mtime: nil,
        restricted: false
      )
    end
    let(:image_response) { instance_double(HTTP::Response, body: StringIO.new, status: 200) }
    let(:projection) { instance_double(Projection, response: image_response, valid?: true) }
    let(:transformation) { double }
    let(:ability) { instance_double(Ability, can?: true, authorize!: true) }

    before do
      allow(IIIF::Image::OptionDecoder).to receive(:decode)
        .with(ActionController::Parameters)
        .and_return(transformation)
      allow(StacksImage).to receive(:new).and_return(image)
      allow(image).to receive(:projection_for).with(transformation).and_return(projection)
      allow(Ability).to receive(:new).and_return(ability)
    end

    # rubocop:disable RSpec/ExampleLength
    it 'tracks downloads' do
      get iiif_path(
        'nr349ct7889%2Fimage',
        {
          id: druid,
          file_name:,
          region: '0,640,2552,2552',
          size: '100,100',
          rotation: '0',
          quality: 'default',
          format: 'jpg',
          download: true
        }
      ), headers: { 'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_6) AppleWebKit/537.36 (KHTML, like Gecko)' },
         env: { 'REMOTE_ADDR' => '73.235.188.148' }

      perform_enqueued_jobs

      expect(a_request(:post, 'https://example.com/ahoy/events').with do |req|
        expect(req.body).to include '"name":"download"'
        expect(req.body).to include "\"druid\":\"#{druid}\""
        expect(req.body).to include "\"file\":\"#{file_name.sub('jp2', 'jpg')}\""
        expect(req.headers['User-Agent']).to eq 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_6) AppleWebKit/537.36 (KHTML, like Gecko)'
        expect(req.headers['X-Forwarded-For']).to eq '73.235.188.148'
      end).to have_been_made
    end
    # rubocop:enable RSpec/ExampleLength
  end
end
