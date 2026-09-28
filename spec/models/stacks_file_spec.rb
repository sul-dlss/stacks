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

  describe '#s3_object' do
    let(:s3_client) { instance_double(Aws::S3::Client) }
    let(:streaming_error) do
      Aws::S3::Plugins::NonRetryableStreamingError.new(
        Seahorse::Client::NetworkingError.new(Errno::ECONNRESET.new)
      )
    end

    before do
      allow(S3ClientFactory).to receive(:create_client).and_return(s3_client)
    end

    it 'resumes after an upstream connection reset without duplicating chunks' do
      calls = 0
      allow(s3_client).to receive(:get_object) do |params, &block|
        calls += 1
        if calls == 1
          block.call('first')
          raise streaming_error
        end

        expect(params[:range]).to eq('bytes=5-')
        block.call('second')
      end

      chunks = []
      instance.s3_object { |chunk| chunks << chunk }

      expect(chunks).to eq(%w[first second])
    end

    it 'advances the resume range after repeated connection resets' do
      calls = 0
      allow(s3_client).to receive(:get_object) do |params, &block|
        calls += 1
        expect(params[:range]).to eq('bytes=5-') if calls == 2
        expect(params[:range]).to eq('bytes=11-') if calls == 3

        block.call(%w[first second third][calls - 1])
        raise streaming_error if calls < 3
      end

      chunks = []
      instance.s3_object { |chunk| chunks << chunk }

      expect(chunks).to eq(%w[first second third])
    end

    it 'does not retry errors raised while writing to the response stream' do
      client_disconnected_error = ActionController::Live::ClientDisconnected.new('client disconnected')
      error = Aws::S3::Plugins::NonRetryableStreamingError.new(client_disconnected_error)
      allow(s3_client).to receive(:get_object).and_raise(error)

      expect { instance.s3_object { |chunk| chunk } }.to raise_error(error)
      expect(s3_client).to have_received(:get_object).once
    end

    it 'raises after exhausting streaming retries' do
      allow(s3_client).to receive(:get_object).and_raise(streaming_error)

      expect { instance.s3_object { |chunk| chunk } }
        .to raise_error(Aws::S3::Plugins::NonRetryableStreamingError)
      expect(s3_client).to have_received(:get_object).exactly(4).times
    end
  end
end
