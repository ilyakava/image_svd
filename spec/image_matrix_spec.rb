# encoding: utf-8

require 'spec_helper'

describe ImageSvd::ImageMatrix do
  before :each do
    @m = Matrix[[0, 1, 1], [1, 1, 0]]
  end

  it 'recovers a 2x3 matrix' do
    i = ImageSvd::ImageMatrix.new([2])
    i.decompose(@m)
    rounded_matrix = Matrix[*i.matrix_to_valid_pixels(i.reconstruct_matrix)]
    # due to numerical instability, even a 2x3 matrix needs to be rounded
    @m.should eq(rounded_matrix)
  end
end
