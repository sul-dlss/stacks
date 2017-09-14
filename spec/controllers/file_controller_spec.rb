require 'rails_helper'

describe FileController do
  before do
    controller.instance_variable_set(:@file, file)
    stub_rights_xml(world_readable_rights_xml)
  end

  let(:identifier) { StacksIdentifier.new(druid: 'xf680rd3068', file_name: 'xf680rd3068_1.jp2') }
  let(:file) { StacksFile.new(id: identifier) }

  describe '#show' do
    subject { get :show, params: { id: 'xf680rd3068', file_name: 'xf680rd3068_1.jp2' } }

    before do
      allow(file).to receive_messages(exist?: true, mtime: Time.zone.now, path: File.join(Rails.root, 'Gemfile'))
    end

    it 'sends the file to the user' do
      expect(controller).to receive(:send_file).with(file.path, disposition: :inline).and_call_original
      subject
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
        expect { assigns(:file) }.not_to raise_exception
        expect(assigns(:file)).to be_a StacksFile
      end
    end

    it 'missing file returns 404 Not Found' do
      expect(controller).to receive(:send_file).and_raise ActionController::MissingFile
      expect(subject.status).to eq 404
    end
  end
end
