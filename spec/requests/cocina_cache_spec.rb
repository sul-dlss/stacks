# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Purging cached public JSON' do
  let(:druid) { 'bc123df4567' }
  let(:other_druid) { 'bb000cr7262' }
  let(:cache) { ActiveSupport::Cache::MemoryStore.new }
  let(:claims) { { sub: 'purl-fetcher', purge_cache: true } }
  let(:headers) { { 'Authorization' => "Bearer #{JWT.encode(claims, Settings.service_token.hmac_secret, 'HS256')}" } }

  before do
    allow(Rails).to receive(:cache).and_return(cache)
    cache.write("purl/#{druid}.json", { 'version' => 5 })
    cache.write("purl/#{druid}.4.json", { 'version' => 4 })
    cache.write("purl/#{druid}.5.json", { 'version' => 5 })
    cache.write("purl/#{other_druid}.json", { 'version' => 1 })
  end

  def cached_keys
    ["purl/#{druid}.json", "purl/#{druid}.4.json", "purl/#{druid}.5.json", "purl/#{other_druid}.json"]
      .select { |key| cache.exist?(key) }
  end

  context 'with a service token with the purge_cache claim' do
    it 'purges the head version' do
      delete("/cocina_cache/#{druid}", headers:)

      expect(response).to have_http_status(:no_content)
      expect(cached_keys).to eq ["purl/#{druid}.4.json", "purl/#{druid}.5.json", "purl/#{other_druid}.json"]
    end

    it 'purges the head version and the given version' do
      delete("/cocina_cache/#{druid}/version/5", headers:)

      expect(response).to have_http_status(:no_content)
      expect(cached_keys).to eq ["purl/#{druid}.4.json", "purl/#{other_druid}.json"]
    end
  end

  context 'with a service token without the purge_cache claim' do
    let(:claims) { { sub: 'sdr-harvest' } }

    it 'is forbidden' do
      delete("/cocina_cache/#{druid}", headers:)

      expect(response).to have_http_status(:forbidden)
      expect(cached_keys.size).to eq 4
    end
  end

  context 'without a token' do
    it 'is forbidden' do
      delete "/cocina_cache/#{druid}"

      expect(response).to have_http_status(:forbidden)
      expect(cached_keys.size).to eq 4
    end
  end
end
