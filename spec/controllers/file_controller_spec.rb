require 'rails_helper'

describe FileController, vcr: { record: :new_episodes } do
  before do
    controller.instance_variable_set(:@file, file)
  end

  let(:file) { StacksFile.new(id: 'xf680rd3068', file_name: 'xf680rd3068_1.jp2') }

  describe '#show' do
    subject { get :show, id: 'xf680rd3068', file_name: 'xf680rd3068_1.jp2' }

    before do
      allow(file).to receive_messages(exist?: true, mtime: Time.zone.now, path: File.join(Rails.root, 'Gemfile'))
    end

    it 'sends the file to the user' do
      expect(controller).to receive(:send_file).with(file.path).and_call_original
      subject
    end

    context 'additional params' do
      subject { get :show, id: 'xf680rd3068', file_name: 'xf680rd3068_1.jp2', ignored: 'ignored', host: 'host' }
      it 'ignored when instantiating StacksFile' do
        expect { assigns(:file) }.not_to raise_exception
        expect(assigns(:file)).to be_a StacksFile
      end
    end

    it 'missing file returns 404 Not Found' do
      expect(controller).to receive(:send_file).with(file.path).and_raise ActionController::MissingFile
      expect(subject.status).to eq 404
    end
  end
end
