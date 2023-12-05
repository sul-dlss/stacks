# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FileController do
  before do
    allow(StacksFile).to receive(:new).and_return(file)
    stub_rights_xml(world_readable_rights_xml)
    allow(Purl).to receive(:public_json).and_return(public_json)
  end

  let(:druid) { 'xf680rd3068' }
  let(:public_json) do
    {
      'structural' => {
        'contains' => [
          {
            'structural' => {
              'contains' => [
                {
                  'filename' => 'xf680rd3068_1.jp2',
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
    }
  end

  let(:file) { StacksFile.new(id: druid, file_name: 'xf680rd3068_1.jp2') }

  describe '#show' do
    subject { get :show, params: { id: druid, file_name: 'xf680rd3068_1.jp2' } }

    before do
      path = File.join(Rails.root, 'spec/fixtures/nr/349/ct/7889/image.jp2')
      allow(file).to receive_messages(mtime: Time.zone.now, path:)
    end

    it 'sends the file to the user' do
      expect(controller).to receive(:send_file).with(file.path, disposition: :inline).and_call_original
      subject
    end

    it 'sends headers for content' do
      expect(controller).to receive(:send_file).with(file.path, disposition: :attachment).and_call_original
      get :show, params: { id: 'xf680rd3068', file_name: 'xf680rd3068_1.jp2', download: 'any' }
      expect(response.headers.to_h).to include 'Content-Length' => 11_043, 'Accept-Ranges' => 'bytes'
    end

    it 'sets disposition attachment with download param' do
      expect(controller).to receive(:send_file).with(file.path, disposition: :attachment).and_call_original
      get :show, params: { id: 'xf680rd3068', file_name: 'xf680rd3068_1.jp2', download: 'any' }
    end

    context 'additional params' do
      subject do
        get :show, params: { id: 'xf680rd3068', file_name: 'xf680rd3068_1.jp2', ignored: 'ignored', host: 'host' }
      end

      it 'ignored when instantiating StacksFile' do
        subject
        expect(StacksFile).to have_received(:new).with(hash_including(id: 'xf680rd3068', file_name: 'xf680rd3068_1.jp2'))
      end
    end

    it 'missing file returns 404 Not Found' do
      expect(controller).to receive(:send_file).and_raise ActionController::MissingFile
      expect(subject.status).to eq 404
    end
  end

  describe '#auth_check' do
    let(:id) { druid }
    let(:file_name) { 'xf680rd3068_1.jp2' }

    it 'returns JSON from hash_for_auth_check' do
      test_hash = { foo: :bar }
      expect(controller).to receive(:hash_for_auth_check).and_return(test_hash)
      get :auth_check, params: { id: druid, file_name:, format: :js }
      body = JSON.parse(response.body)
      expect(body).to eq('foo' => 'bar')
    end

    context 'success' do
      before do
        allow(controller).to receive(:can?).and_return(true)

        next unless Settings.features.cocina # below mocking is only needed if cocina is being parsed instead of legacy rights XML

        stacks_file = instance_double(StacksFile, id:, file_name:, stanford_restricted?: false, restricted_by_location?: false,
                                                  embargoed?: false, embargo_release_date: nil)
        allow(controller).to receive(:current_file).and_return(stacks_file)
      end

      it 'returns json that indicates a successful auth check' do
        get :auth_check, params: { id:, file_name:, format: :js }
        body = JSON.parse(response.body)
        expect(body['status']).to eq 'success'
      end

      it 'returns info about applicable access restrictions' do
        get :auth_check, params: { id:, file_name:, format: :js }
        body = JSON.parse(response.body)
        expect(body['access_restrictions']).to eq({
                                                    'stanford_restricted' => false,
                                                    'restricted_by_location' => false,
                                                    'embargoed' => false,
                                                    'embargo_release_date' => nil
                                                  })
      end
    end
  end
end
