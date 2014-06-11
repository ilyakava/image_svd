# encoding: utf-8

require 'spec_helper'

describe 'CLI' do
  describe 'integration spec for grayscale images' do
    let(:cli) { ImageSvd::CLI.new }
    let(:orig) { File.new('./spec/fixtures/2x2.jpg') }
    let(:default_opts) do
      {
        input_file: orig,
        convert: true,
        num_singular_values: '2',
        grayscale: true
      }
    end

    it 'converts an image without too great errors' do
      conv = './spec/fixtures/svd_image_output'
      cli.run(default_opts.merge(output_name: conv))
      i = ImageSvd::ImageMatrix.new([2], true)
      i.read_image(orig)
      i2 = ImageSvd::ImageMatrix.new([2], true)
      i2.read_image(File.new("#{conv}_2_svs.jpg"))
      m = i.channels.first.reconstruct_matrix
      m2 = i2.channels.first.reconstruct_matrix
      diff_matrix = m - m2
      diff_matrix.to_a.flatten.each do |diff_component|
        diff_component.abs.should be < 5
      end

      # cleanup
      %x(rm #{conv}_2_svs.jpg)
    end

    it 'archives, reads, and converts an image without too great errors' do
      conv = './spec/fixtures/svd_image_output'
      # archive
      cli.run(default_opts.merge(
        archive: true,
        output_name: conv
      ))
      # read archive and write and image
      cli.run(default_opts.merge(
        input_file: "#{conv}.svdim",
        read: true,
        output_name: "#{conv}_two"
      ))
      i = ImageSvd::ImageMatrix.new([2], true)
      i.read_image(orig)
      i2 = ImageSvd::ImageMatrix.new([2], true)
      i2.read_image(File.new("#{conv}_two_2_svs.jpg"))
      m = i.channels.first.reconstruct_matrix
      m2 = i2.channels.first.reconstruct_matrix
      diff_matrix = m - m2
      diff_matrix.to_a.flatten.each do |diff_component|
        diff_component.abs.should be < 5
      end
      # cleanup
      %x(rm #{conv}_two_2_svs.jpg #{conv}.svdim)
    end
  end
end
