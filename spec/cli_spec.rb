# encoding: utf-8

require 'spec_helper'

describe 'CLI' do
  describe 'integration spec' do
    let(:cli) { ImageSvd::CLI.new }
    let(:orig) { File.new('./spec/fixtures/2x2.jpg') }

    it 'converts an image without too great errors' do
      conv = './spec/fixtures/svd_image_output'
      cli.run(
        input_file: orig,
        convert: true,
        num_singular_values: 2,
        output_name: conv
      )
      i = ImageSvd::ImageMatrix.new(2)
      i.read_image(orig)
      i2 = ImageSvd::ImageMatrix.new(2)
      i2.read_image(File.new("#{conv}.jpg"))
      diff_matrix = i.reconstruct_matrix - i2.reconstruct_matrix
      diff_matrix.to_a.flatten.each do |diff_component|
        diff_component.abs.should be < 5
      end

      # cleanup
      %x(rm #{conv}.jpg)
    end

    it 'archives, reads, and converts an image without too great errors' do
      conv = './spec/fixtures/svd_image_output'
      # archive
      cli.run(
        input_file: orig,
        archive: true,
        num_singular_values: 2,
        output_name: conv
      )
      # read archive and write and image
      cli.run(
        input_file: "#{conv}.svdim",
        read: true,
        output_name: "#{conv}_2"
      )
      i = ImageSvd::ImageMatrix.new(2)
      i.read_image(orig)
      i2 = ImageSvd::ImageMatrix.new(2)
      i2.read_image(File.new("#{conv}_2.jpg"))
      diff_matrix = i.reconstruct_matrix - i2.reconstruct_matrix
      diff_matrix.to_a.flatten.each do |diff_component|
        diff_component.abs.should be < 5
      end
      # cleanup
      %x(rm #{conv}_2.jpg #{conv}.svdim)
    end
  end
end
