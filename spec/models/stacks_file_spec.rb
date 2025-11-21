# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StacksFile do
  let(:file_name) { 'image.jp2' }
  let(:cocina) { Cocina.new(public_json) }
  let(:instance) { described_class.new(file_name:, cocina:) }
  let(:path) { storage_root.absolute_path }
  let(:storage_root) { StorageRoot.new(cocina:, file_name:) }
  let(:public_json) { Factories.cocina_with_file }

  context 'with a missing file name' do
    let(:file_name) { nil }

    it 'raises an error' do
      expect { instance }.to raise_error ActiveModel::ValidationError
    end
  end
end
