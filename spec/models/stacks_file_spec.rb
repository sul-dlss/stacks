# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StacksFile do
  let(:file_name) { 'image.jp2' }
  let(:cocina) { Cocina.new(public_json) }
  let(:instance) { described_class.new(file_name:, cocina:) }
  let(:path) { storage_root.absolute_path }
  let(:storage_root) { StorageRoot.new(cocina:, file_name:) }
  let(:public_json) { Factories.cocina_with_file }

  describe '#download_proxy_path' do
    it 'escapes reserved characters without changing path separators' do
      allow(StorageRoot).to receive(:new).and_return(instance_double(StorageRoot, relative_path: 'content/a b%?#.jp2'))

      expect(instance.download_proxy_path).to eq '/_private_s3/content/a%20b%25%3F%23.jp2'
    end
  end

  context 'with a missing file name' do
    let(:file_name) { nil }

    it 'raises an error' do
      expect { instance }.to raise_error ActiveModel::ValidationError
    end
  end
end
