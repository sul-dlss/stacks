# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FileController do
  before do
    allow(Cocina).to receive(:find).and_return(Cocina.new(public_json))
  end

  let(:public_json) do
    Factories.cocina_with_file
  end

  let(:stanford_json) do
    {
      'structural' => {
        'contains' => [
          {
            'structural' => {
              'contains' => [
                {
                  'filename' => 'xf680rd3068_1.jp2',
                  'access' => {
                    'view' => 'stanford',
                    'download' => 'stanford'
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
    let(:druid) { 'nr349ct7889' }

    let(:path) { 'spec/fixtures/nr/349/ct/7889/image.jp2' }
    subject { get :show, params: { id: druid, file_name: 'image.jp2' } }

    it 'sends the file to the user' do
      expect(controller).to receive(:send_file).with(path, filename: 'image.jp2', disposition: :inline).and_call_original
      subject
      expect(response.headers.to_h).to include 'Access-Control-Allow-Origin' => '*'
    end

    context 'when file is not in a content addressable path' do
      it 'returns legacy file' do
        expect(controller).to receive(:send_file).with(path, filename: 'image.jp2', disposition: :attachment).and_call_original
        get :show, params: { id: druid, file_name: 'image.jp2', download: 'any' }
        expect(response.headers.to_h).to include(
          'content-length' => 11_043,
          'accept-ranges' => 'bytes',
          "content-disposition" => "attachment; filename=\"image.jp2\"; filename*=UTF-8''image.jp2"
        )
      end

      it 'sets disposition attachment with download param' do
        expect(controller).to receive(:send_file).with(file.path, disposition: :attachment).and_call_original
        get :show, params: { id: 'xf680rd3068', file_name: 'xf680rd3068_1.jp2', download: 'any' }
      end

      context 'when Stanford restricted' do
        before do
          # stub_rights_xml(stanford_restricted_rights_xml)
          allow(Purl).to receive(:public_json).and_return(stanford_json)
        end

        it 'sends host-specific and credentials CORS headers' do
          subject
          expect(response.headers.to_h).to include 'Access-Control-Allow-Origin' => 'https://embed.stanford.edu',
                                                   'Access-Control-Allow-Credentials' => 'true'
        end
      end
    end

    context 'when file is in a content addressable path' do
      let(:path) { 'spec/fixtures/nr/349/ct/7889/nr349ct7889/content/02f77c96c40ad3c7c843baa9c7b2ff2c' }
      around do |ex|
        FileUtils.mkdir_p('spec/fixtures/nr/349/ct/7889/nr349ct7889/content/')
        File.link('spec/fixtures/nr/349/ct/7889/image.jp2', path)
        ex.run
        File.unlink(path)
      end

      it 'sends headers for content' do
        expect(controller).to receive(:send_file).with(path, filename: 'image.jp2', disposition: :attachment).and_call_original
        get :show, params: { id: druid, file_name: 'image.jp2', download: 'any' }
        expect(response.headers.to_h).to include(
          'content-length' => 11_043,
          'accept-ranges' => 'bytes',
          "content-disposition" => "attachment; filename=\"image.jp2\"; filename*=UTF-8''image.jp2"
        )
      end
    end

    it 'missing file returns 404 Not Found' do
      expect(controller).to receive(:send_file).and_raise ActionController::MissingFile
      expect(subject.status).to eq 404
    end
  end
end
