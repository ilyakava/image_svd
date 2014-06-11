# encoding: utf-8

require 'spec_helper'

describe 'ImageSvd::Options' do
  describe 'numSingValsToOutputFromArchive' do
    it 'returns the number of sing vals available when none are requested' do
      o = ImageSvd::Options.numSingValsToOutputFromArchive([6], 20)
      o.should eq([6])
    end

    it 'allows the requested number of sing vals when more are available' do
      o = ImageSvd::Options.numSingValsToOutputFromArchive([6], 20)
      o.should eq([6])
    end

    it 'returns the number of sing vals available if more are requested' do
      o = ImageSvd::Options.numSingValsToOutputFromArchive([400], 20)
      o.should eq([20])
    end

    it 'returns the valid segment of a range of sing vals requested' do
      o = ImageSvd::Options.numSingValsToOutputFromArchive((1..40).to_a, 20)
      o.should eq((1..20).to_a)
    end
  end
end
