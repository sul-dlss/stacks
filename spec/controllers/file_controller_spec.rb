# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FileController do
  before do
    allow(Cocina).to receive(:find).and_return(Cocina.new(public_json))
  end

  let(:public_json) do
    {
      'externalIdentifier' => druid,
      'structural' => {
        'contains' => [
          {
            'structural' => {
              'contains' => [
                {
                  'filename' => 'image.jp2',
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

  describe '#show' do
    let(:druid) { 'nr349ct7889' }

    let(:path) { 'spec/fixtures/nr/349/ct/7889/image.jp2' }
    subject { get :show, params: { id: druid, file_name: 'image.jp2' } }

    it 'sends the file to the user' do
      expect(controller).to receive(:send_file).with(path, disposition: :inline).and_call_original
      subject
    end

    it 'sends headers for content' do
      expect(controller).to receive(:send_file).with(path, disposition: :attachment).and_call_original
      get :show, params: { id: druid, file_name: 'image.jp2', download: 'any' }
      expect(response.headers.to_h).to include 'content-length' => 11_043, 'accept-ranges' => 'bytes'
    end

    it 'missing file returns 404 Not Found' do
      expect(controller).to receive(:send_file).and_raise ActionController::MissingFile
      expect(subject.status).to eq 404
    end
  end
end
