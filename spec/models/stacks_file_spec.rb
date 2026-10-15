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
    let(:s3_client) { S3ClientFactory.create_client }
    let(:content) { read_all(instance) }
    let(:connection_reset) do
      Seahorse::Client::NetworkingError.new(Errno::ECONNRESET.new, 'Connection reset by peer - SSL_read')
    end

    def read_all(file, **)
      (+'').b.tap { |bytes| file.s3_object(**) { |chunk| bytes << chunk } }
    end

    before do
      content
      allow(S3ClientFactory).to receive(:create_client).and_return(s3_client)
    end

    context 'when S3 drops the connection partway through' do
      before do
        calls = 0
        allow(s3_client).to receive(:get_object).and_wrap_original do |original, params, &block|
          calls += 1
          next original.call(params, &block) if calls > 2

          # Send the first 100 bytes of what was asked for, then fail
          original.call(params) do |chunk|
            block.call(chunk.byteslice(0, 100))
            raise connection_reset
          end
        end
      end

      it 'resumes after the last byte it yielded' do
        expect(read_all(instance)).to eq content
        expect(s3_client).to have_received(:get_object).with(hash_including(range: 'bytes=0-11042')).ordered
        expect(s3_client).to have_received(:get_object).with(hash_including(range: 'bytes=100-11042')).ordered
        expect(s3_client).to have_received(:get_object).with(hash_including(range: 'bytes=200-11042')).ordered
      end

      it 'resumes within a range' do
        range = RangeHeader::Range.new(50, 349)
        expect(read_all(instance, range:)).to eq content.byteslice(50, 300)
        expect(s3_client).to have_received(:get_object).with(hash_including(range: 'bytes=150-349')).ordered
        expect(s3_client).to have_received(:get_object).with(hash_including(range: 'bytes=250-349')).ordered
      end
    end

    context 'when S3 keeps dropping the connection' do
      before do
        allow(s3_client).to receive(:get_object).and_raise(connection_reset)
      end

      it 'gives up' do
        expect { read_all(instance) }.to raise_error(connection_reset)
        expect(s3_client).to have_received(:get_object).exactly(described_class::S3_RESUME_LIMIT + 1).times
      end
    end

    context 'when writing a chunk fails' do
      # The S3 client wraps errors raised by the block in a NetworkingError
      it "doesn't ask S3 again" do
        allow(s3_client).to receive(:get_object).and_call_original
        expect { instance.s3_object { raise Errno::EPIPE } }.to raise_error(Seahorse::Client::NetworkingError)
        expect(s3_client).to have_received(:get_object).once
      end
    end
  end
end
