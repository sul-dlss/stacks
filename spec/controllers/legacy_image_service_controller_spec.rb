require 'rails_helper'

describe LegacyImageServiceController, :vcr do
  describe 'Precast sizes' do
    context 'squares' do
      it 'works' do
        page = get :show, id: 'nr349ct7889', file_name: 'nr349ct7889_00_0001_square'
        expect(page).to redirect_to '/image/iiif/nr349ct7889%2Fnr349ct7889_00_0001/0,640,2552,2552/100,100/0/default.jpg'
      end
    end

    context 'thumbs' do
      it 'works' do
        page = get :show, id: 'nr349ct7889', file_name: 'nr349ct7889_00_0001_thumb'
        expect(page).to redirect_to '/image/iiif/nr349ct7889%2Fnr349ct7889_00_0001/full/!400,400/0/default.jpg'
      end
    end

    context 'small' do
      it 'works' do
        page = get :show, id: 'nr349ct7889', file_name: 'nr349ct7889_00_0001_small'
        expect(page).to redirect_to '/image/iiif/nr349ct7889%2Fnr349ct7889_00_0001/full/pct:6.25/0/default.jpg'
      end
    end

    context 'medium' do
      it 'works' do
        page = get :show, id: 'nr349ct7889', file_name: 'nr349ct7889_00_0001_medium'
        expect(page).to redirect_to '/image/iiif/nr349ct7889%2Fnr349ct7889_00_0001/full/pct:12.5/0/default.jpg'
      end
    end

    context 'large' do
      it 'works' do
        page = get :show, id: 'nr349ct7889', file_name: 'nr349ct7889_00_0001_large'
        expect(page).to redirect_to '/image/iiif/nr349ct7889%2Fnr349ct7889_00_0001/full/pct:25/0/default.jpg'
      end
    end

    context 'xlarge' do
      it 'works' do
        page = get :show, id: 'nr349ct7889', file_name: 'nr349ct7889_00_0001_xlarge'
        expect(page).to redirect_to '/image/iiif/nr349ct7889%2Fnr349ct7889_00_0001/full/pct:50/0/default.jpg'
      end
    end

    context 'full' do
      it 'works' do
        page = get :show, id: 'nr349ct7889', file_name: 'nr349ct7889_00_0001_full'
        expect(page).to redirect_to '/image/iiif/nr349ct7889%2Fnr349ct7889_00_0001/full/full/0/default.jpg'
      end
    end

    context 'zpr' do
      it 'works' do
        page = get :show, id: 'nr349ct7889', file_name: 'nr349ct7889_00_0001', format: 'jpg', zoom: 100, region: '0,0,256,256'
        expect(page).to redirect_to '/image/iiif/nr349ct7889%2Fnr349ct7889_00_0001/0,0,256,256/pct:100/0/default.jpg'
      end

      it 'works' do
        page = get :show, id: 'nr349ct7889', file_name: 'nr349ct7889_00_0001', format: 'jpg', zoom: 50, region: '0,0,256,256'
        expect(page).to redirect_to '/image/iiif/nr349ct7889%2Fnr349ct7889_00_0001/0,0,512,512/pct:50/0/default.jpg'
      end

      it 'works' do
        page = get :show, id: 'nr349ct7889', file_name: 'nr349ct7889_00_0001', format: 'jpg', zoom: 25, region: '0,0,256,256'
        expect(page).to redirect_to '/image/iiif/nr349ct7889%2Fnr349ct7889_00_0001/0,0,1024,1024/pct:25/0/default.jpg'
      end

      it 'works' do
        page = get :show, id: 'nr349ct7889', file_name: 'nr349ct7889_00_0001', format: 'jpg', zoom: 50, region: '256,256,256,256'
        expect(page).to redirect_to '/image/iiif/nr349ct7889%2Fnr349ct7889_00_0001/512,512,512,512/pct:50/0/default.jpg'
      end

      it 'works' do
        page = get :show, id: 'nr349ct7889', file_name: 'nr349ct7889_00_0001', format: 'jpg', zoom: 50, rotate: 90, region: '256,256,256,256'
        expect(page).to redirect_to '/image/iiif/nr349ct7889%2Fnr349ct7889_00_0001/512,512,512,512/pct:50/90/default.jpg'
      end

      it 'works' do
        page = get :show, id: 'nr349ct7889', file_name: 'nr349ct7889_00_0001', format: 'png', zoom: 50, rotate: 90, region: '256,256,256,256'
        expect(page).to redirect_to '/image/iiif/nr349ct7889%2Fnr349ct7889_00_0001/512,512,512,512/pct:50/90/default.png'
      end
    end
  end
end
