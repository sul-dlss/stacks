# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FileController do
  before do
    allow(Cocina).to receive(:find).and_return(Cocina.new(public_json))
  end

  let(:public_json) do
    Factories.cocina_with_file
  end

  describe '#show' do
    let(:druid) { 'bb000cr7262' }

    context 'when file is in a content addressable path' do
      let(:path) { 'spec/fixtures/bb/000/cr/7262/bb000cr7262/content/8ff299eda08d7c506273840d52a03bf3' }

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
      get :show, params: { id: druid, file_name: 'image.jp2' }

      expect(response).to have_http_status :not_found
    end
  end
end
