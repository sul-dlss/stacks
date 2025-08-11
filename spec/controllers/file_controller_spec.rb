# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FileController do
  before do
    allow(Cocina).to receive(:find).and_return(Cocina.new(public_json))
  end

  let(:public_json) do
    Factories.legacy_cocina_with_file
  end

  describe '#show' do
    subject { get :show, params: { id: druid, file_name: 'image.jp2' } }

    let(:druid) { 'nr349ct7889' }

    let(:path) { 'spec/fixtures/nr/349/ct/7889/image.jp2' }

    it 'sends the file to the user' do
      expect(controller).to receive(:send_file).with(path, filename: 'image.jp2', disposition: :inline).and_call_original
      subject
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
