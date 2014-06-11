# encoding: utf-8

require 'spec_helper'

describe ImageSvd::ImageMatrix do
  before :each do
    @m = Matrix[[0, 1, 1], [1, 1, 0]]
  end

  it 'recovers a 2x3 matrix' do
    c = ImageSvd::Channel.new(@m, 2)
    c.decompose
    rounded_matrix = Matrix[
      *ImageSvd::ImageMatrix.matrix_to_valid_pixels(c.reconstruct_matrix)
    ]
    # due to numerical instability, even a 2x3 matrix needs to be rounded
    @m.should eq(rounded_matrix)
  end
end
