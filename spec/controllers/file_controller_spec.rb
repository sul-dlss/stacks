require 'rails_helper'

describe FileController, vcr: { record: :new_episodes } do
  before do
    controller.instance_variable_set(:@file, file)
  end

  let(:file) { StacksFile.new(id: 'xf680rd3068', file_name: 'xf680rd3068_1.jp2') }

  describe '#show' do
    subject { get :show, id: 'xf680rd3068', file_name: 'xf680rd3068_1.jp2' }

    before do
      allow(file).to receive_messages(exist?: true, mtime: Time.now, path: File.join(Rails.root, 'Gemfile'))
    end

    it 'sends the file to the user' do
      expect(controller).to receive(:send_file).with(file.path).and_call_original
      subject
    end
  end
end
