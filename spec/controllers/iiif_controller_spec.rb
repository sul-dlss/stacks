require 'rails_helper'

describe IiifController, :vcr do
  before do
    allow_any_instance_of(StacksImage).to receive(:image_exist?).and_return(true)
  end

  describe '#show' do
    subject { get :show, identifier: 'nr349ct7889%2Fnr349ct7889_00_0001', region: '0,640,2552,2552', size: '100,100', rotation: '0', quality: 'default', format: 'jpg' }

    it 'loads the image' do
      subject
      image = controller.instance_variable_get(:@image)
      expect(image).to be_a_kind_of StacksImage
      expect(image.region).to eq '0,640,2552,2552'
      expect(image.size).to eq '100,100'
      expect(image.rotation).to eq '0'
    end

    it 'sets the content type' do
      subject
      expect(controller.content_type).to eq 'image/jpeg'
    end
  end

  describe '#metadata' do
    subject { get :metadata, identifier: 'nr349ct7889%2Fnr349ct7889_00_0001' }

    it 'provides iiif info.json responses' do
      subject
      expect(controller.content_type).to eq 'application/json'
      expect(controller.response_body.first).to match('@context')
    end

    it 'includes a recommended tile size' do
      allow(controller).to receive(:can?).and_return(true)
      subject
      info = JSON.parse(controller.response_body.first)
      expect(info['tiles'].first).to include "width" => 1024, "height" => 1024
    end
  end
end