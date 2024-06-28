# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StacksMediaStream do
  let(:instance) { described_class.new(stacks_file:) }
  let(:stacks_file) { instance_double(StacksFile, stacks_rights:) }

  describe '#stanford_restricted?' do
    subject { instance.stanford_restricted? }

    context 'when restricted' do
      let(:stacks_rights) { instance_double(StacksRights, stanford_restricted?: true) }

      it { is_expected.to be true }
    end

    context 'when not restricted' do
      let(:stacks_rights) { instance_double(StacksRights, stanford_restricted?: false) }

      it { is_expected.to be false }
    end
  end
end
