# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DjatokaInfoService do
  describe '#image_width' do
    let(:image) { StacksImage.new(id: 'nr349ct7889', file_name: 'nr349ct7889_00_0001') }
    let(:service) { described_class.new image }

    subject { service.image_width }
    it "Returns the width of the image" do
      expect(subject).to eq 0
    end
  end
end
