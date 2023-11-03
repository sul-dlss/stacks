# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FileController do
  before do
    allow(StacksFile).to receive(:new).and_return(file)
    stub_rights_xml(world_readable_rights_xml)
  end

  let(:file) { StacksFile.new(id: druid, file_name: 'xf680rd3068_1.jp2') }

  describe '#show' do
    let(:druid) { 'xf680rd3068' }
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
end
