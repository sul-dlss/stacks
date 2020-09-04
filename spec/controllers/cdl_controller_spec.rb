# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CdlController do
  let(:user) { User.new id: 'username', jwt_tokens: [token] }
  let(:token) { JWT.encode(payload, Settings.cdl.jwt.secret, Settings.cdl.jwt.algorithm) }
  let(:payload) { { aud: 'druid', sub: 'username', exp: (Time.zone.now + 1.day).to_i, barcode: '36105110268922' } }

  let(:barcoded_item_xml) do
    <<-EOXML
      <publicObject>
        <identityMetadata>
          <sourceId source="sul">36105110268922</sourceId>
        </identityMetadata>
      </publicObject>
    EOXML
  end

  let(:non_barcoded_item_xml) do
    <<-EOXML
      <publicObject>
        <identityMetadata>
          <sourceId source="sul">this is not a barcode</sourceId>
        </identityMetadata>
      </publicObject>
    EOXML
  end

  before do
    allow(controller).to receive(:current_user).and_return(user)
    cookies.encrypted[:tokens] = [token]
  end

  describe '#show' do
    context 'without a token' do
      before do
        allow(Purl).to receive(:public_xml).with('other-druid').and_return(barcoded_item_xml)
      end

      it 'includes a url to look up availability' do
        get :show, { params: { id: 'other-druid' } }

        expect(response.status).to eq 200
        expect(JSON.parse(response.body).with_indifferent_access).to include(
          availability_url: match(%(cdl/availability/36105110268922))
        )
      end
    end

    it 'renders some information from the token' do
      get :show, { params: { id: 'druid' } }

      expect(response.status).to eq 200
      expect(JSON.parse(response.body).with_indifferent_access).to include(
        payload: hash_including(sub: 'username', aud: 'druid', exp: a_kind_of(Numeric))
      )
    end

    it 'includes a url to look up availability' do
      get :show, { params: { id: 'druid' } }

      expect(JSON.parse(response.body).with_indifferent_access).to include(
        availability_url: match(%(cdl/availability/36105110268922))
      )
    end
  end

  describe '#create' do
    context 'with a token' do
      let(:new_token) do
        JWT.encode(payload.merge(aud: 'other-druid'), Settings.cdl.jwt.secret, Settings.cdl.jwt.algorithm)
      end

      it 'stores the token in a cookie' do
        get :create_success, { params: { id: 'other-druid', token: new_token } }

        expect(cookies.encrypted[:tokens].length).to eq 2
      end
    end

    context 'with an updated token' do
      let(:new_exp) { 2.days.from_now.to_i }
      let(:new_token) do
        JWT.encode(
          payload.merge(iat: Time.zone.now.to_i, exp: new_exp),
          Settings.cdl.jwt.secret,
          Settings.cdl.jwt.algorithm
        )
      end

      it 'stores the token in a cookie' do
        get :create_success, { params: { id: 'druid', token: new_token } }

        expect(cookies.encrypted[:tokens].length).to eq 1
        expect(controller.send(:current_user).cdl_tokens.first[:exp]).to eq new_exp
      end
    end

    it 'bounces you to requests to handle the symphony interaction' do
      allow(Purl).to receive(:public_xml).with('other-druid').and_return(barcoded_item_xml)

      get :create, { params: { id: 'other-druid' } }

      expect(response).to redirect_to('https://requests.stanford.edu/cdl/checkout?barcode=36105110268922&id=other-druid&modal=true&return_to=http%3A%2F%2Ftest.host%2Fauth%2Fiiif%2Fcdl%2Fother-druid%2Fcheckout%2Fsuccess')
    end

    context 'with a record without a barcode' do
      it 'is a 400' do
        allow(Purl).to receive(:public_xml).with('other-druid').and_return(non_barcoded_item_xml)
        get :create, { params: { id: 'other-druid' } }

        expect(response.status).to eq 400
      end
    end
  end

  describe '#delete' do
    context 'with a success parameter' do
      it 'purges the cookie' do
        get :delete_success, params: { id: 'druid' }

        expect(cookies.encrypted[:tokens].length).to eq 0
      end
    end

    it 'bounces you to requests to handle the symphony interaction' do
      get :delete, params: { id: 'druid' }

      url = 'http%3A%2F%2Ftest.host%2Fauth%2Fiiif%2Fcdl%2Fdruid%2Fcheckin%2Fsuccess'
      expect(response).to redirect_to("https://requests.stanford.edu/cdl/checkin?return_to=#{url}&token=#{token}")
    end
  end
end
