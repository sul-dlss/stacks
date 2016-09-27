require 'rails_helper'

describe LegacyImageServiceController do
  describe 'Precast sizes' do
    context 'squares' do
      it 'works' do
        page = get :show, params: { id: 'nr349ct7889', file_name: 'nr349ct7889_00_0001', size: 'square' }
        expect(page).to redirect_to '/image/iiif/nr349ct7889%2Fnr349ct7889_00_0001/square/100,100/0/default.jpg'
      end
    end

    context 'thumbs' do
      it 'works' do
        page = get :show, params: { id: 'nr349ct7889', file_name: 'nr349ct7889_00_0001', size: 'thumb' }
        expect(page).to redirect_to '/image/iiif/nr349ct7889%2Fnr349ct7889_00_0001/full/!400,400/0/default.jpg'
      end
    end

    context 'small' do
      it 'works' do
        page = get :show, params: { id: 'nr349ct7889', file_name: 'nr349ct7889_00_0001', size: 'small' }
        expect(page).to redirect_to '/image/iiif/nr349ct7889%2Fnr349ct7889_00_0001/full/pct:6.25/0/default.jpg'
      end
    end

    context 'medium' do
      it 'works' do
        page = get :show, params: { id: 'nr349ct7889', file_name: 'nr349ct7889_00_0001', size: 'medium' }
        expect(page).to redirect_to '/image/iiif/nr349ct7889%2Fnr349ct7889_00_0001/full/pct:12.5/0/default.jpg'
      end
    end

    context 'large' do
      it 'works' do
        page = get :show, params: { id: 'nr349ct7889', file_name: 'nr349ct7889_00_0001', size: 'large' }
        expect(page).to redirect_to '/image/iiif/nr349ct7889%2Fnr349ct7889_00_0001/full/pct:25/0/default.jpg'
      end
    end

    context 'xlarge' do
      it 'works' do
        page = get :show, params: { id: 'nr349ct7889', file_name: 'nr349ct7889_00_0001', size: 'xlarge' }
        expect(page).to redirect_to '/image/iiif/nr349ct7889%2Fnr349ct7889_00_0001/full/pct:50/0/default.jpg'
      end
    end

    context 'full' do
      it 'works' do
        page = get :show, params: { id: 'nr349ct7889', file_name: 'nr349ct7889_00_0001', size: 'full' }
        expect(page).to redirect_to '/image/iiif/nr349ct7889%2Fnr349ct7889_00_0001/full/full/0/default.jpg'
      end
    end
  end
  context 'delivering tiles' do
    it 'works at 100% zoom' do
      page = get :show, params: { id: 'nr349ct7889',
                                  file_name: 'nr349ct7889_00_0001',
                                  format: 'jpg',
                                  zoom: 100,
                                  region: '0,0,256,256' }
      expect(page).to redirect_to '/image/iiif/nr349ct7889%2Fnr349ct7889_00_0001/0,0,256,256/pct:100/0/default.jpg'
    end

    it 'works at 50% zome' do
      page = get :show, params: { id: 'nr349ct7889',
                                  file_name: 'nr349ct7889_00_0001',
                                  format: 'jpg',
                                  zoom: 50,
                                  region: '0,0,256,256' }
      expect(page).to redirect_to '/image/iiif/nr349ct7889%2Fnr349ct7889_00_0001/0,0,512,512/pct:50/0/default.jpg'
    end

    it 'works at 25% zoom' do
      page = get :show, params: { id: 'nr349ct7889',
                                  file_name: 'nr349ct7889_00_0001',
                                  format: 'jpg',
                                  zoom: 25,
                                  region: '0,0,256,256' }

      expect(page).to redirect_to '/image/iiif/nr349ct7889%2Fnr349ct7889_00_0001/0,0,1024,1024/pct:25/0/default.jpg'
    end

    it 'works at 50% zoom with an offset' do
      page = get :show, params: { id: 'nr349ct7889',
                                  file_name: 'nr349ct7889_00_0001',
                                  format: 'jpg',
                                  zoom: 50,
                                  region: '256,256,256,256' }

      expect(page).to redirect_to '/image/iiif/nr349ct7889%2Fnr349ct7889_00_0001/512,512,512,512/pct:50/0/default.jpg'
    end

    it 'works with a rotation' do
      page = get :show, params: { id: 'nr349ct7889',
                                  file_name: 'nr349ct7889_00_0001',
                                  format: 'jpg',
                                  zoom: 50,
                                  rotate: 90,
                                  region: '256,256,256,256' }

      expect(page).to redirect_to '/image/iiif/nr349ct7889%2Fnr349ct7889_00_0001/512,512,512,512/pct:50/90/default.jpg'
    end

    it 'works with a download link' do
      page = get :show, params: { id: 'nr349ct7889',
                                  file_name: 'nr349ct7889_00_0001',
                                  format: 'jpg',
                                  zoom: 100,
                                  region: '0,0,256,256',
                                  download: 'true' }

      expected_url = '/image/iiif/nr349ct7889%2Fnr349ct7889_00_0001/0,0,256,256/pct:100/0/default.jpg?download=true'
      expect(page).to redirect_to expected_url
    end

    it 'works with a different image format' do
      page = get :show, params: { id: 'nr349ct7889',
                                  file_name: 'nr349ct7889_00_0001',
                                  format: 'png',
                                  zoom: 50,
                                  rotate: 90,
                                  region: '256,256,256,256' }

      expect(page).to redirect_to '/image/iiif/nr349ct7889%2Fnr349ct7889_00_0001/512,512,512,512/pct:50/90/default.png'
    end

    it 'works with fractional zooms' do
      page = get :show, params: { id: 'nr349ct7889',
                                  file_name: 'nr349ct7889_00_0001',
                                  format: 'jpg',
                                  zoom: '0.78125',
                                  rotate: '0',
                                  region: '0,0,256,256' }

      expected = '/image/iiif/nr349ct7889%2Fnr349ct7889_00_0001/0,0,32768,32768/pct:0.78125/0/default.jpg'
      expect(page).to redirect_to expected
    end

    it 'works with incompletely specified regions' do
      page = get :show, params: { id: 'nr349ct7889',
                                  file_name: 'nr349ct7889_00_0001',
                                  format: 'jpg',
                                  region: '0,0,256',
                                  zoom: '100' }
      expected = '/image/iiif/nr349ct7889%2Fnr349ct7889_00_0001/0,0,256,0/pct:100/0/default.jpg'
      expect(page).to redirect_to expected
    end
  end
end
