require 'matrix'
require 'json'
require 'pnm'

module ImageSvd
  # rubocop:disable SymbolName
  # rubocop:disable VariableName

  # This class is responsible for manipulating matricies that correspond
  # to the color channels in images, which includes performing Singular
  # Value Decomposition on a matrix
  class Channel
    attr_accessor :sigma_vTs, :us, :m, :n
    attr_reader :num_singular_values

    def initialize(matrix, num_singular_values)
      fail 'Channel initialized without a matrix' unless matrix.is_a? Matrix
      @matrix = matrix
      @num_singular_values = num_singular_values
    end

    # The most time consuming method
    # Launches the decomposition and saves the two lists
    # of vectors needed to reconstruct the image
    # rubocop:disable MethodLength
    def decompose(m_A = nil)
      m_A ||= @matrix
      m_AT = m_A.transpose
      @m, @n = m_A.to_a.length, m_A.to_a.first.length
      m_ATA = m_AT * m_A
      # linear regression from several images over 200px wide
      eta = (0 < (t = (0.0003541 * (@m * @n) - 10.541)) ? t : 0)
      puts "Searching for eigenvalues... Estimated Time: #{eta.floor} seconds"
      dcmp = Matrix::EigenvalueDecomposition.new(m_ATA)
      evs = dcmp.eigenvalues
      # eigenvectors are already normalized and in same order as eigenvalues
      sorted_eigenvectors = dcmp.eigenvectors.each_with_index
        .sort_by { |_v, i| -evs[i] }
        .map { |v, _idx| v }
      both = (0...@num_singular_values).map do |idx|
        u = sorted_eigenvectors[idx]
        sigma_vT = (m_A * u).covector
        [u, sigma_vT]
      end
      @sigma_vTs = both.map { |p| p.last }
      @us = both.map { |p| p.first }
      self
    end
    # rubocop:enable MethodLength

    def reconstruct_matrix(num_singular_values = nil)
      num_singular_values ||= @num_singular_values
      zero_matrix = Matrix[*Array.new(@n) { Array.new(@m) { 0 } }]
      (0...num_singular_values).reduce(zero_matrix) do |acc, idx|
        acc + (@us[idx] * @sigma_vTs[idx])
      end.transpose
    end
  end

  # This class is responsible for:
  # Reading an image or archive to a matrix
  # Saving a matrix to an image
  class ImageMatrix
    include ImageSvd::Util

    attr_reader :singular_values, :grayscale
    attr_accessor :channels

    def initialize(singular_values, grayscale)
      fail 'not enough singular values' if singular_values.length.zero?
      @singular_values = singular_values
      @num_singular_values = singular_values.max
      @grayscale = grayscale
      @channels = []
    end

    def get_image_channels(image_path)
      puts 'Reading image and converting to matrix...'
      intermediate = extension_swap(image_path.path, 'pgm')
      %x(convert #{image_path.path} #{intermediate})
      if @grayscale
        channels = [Matrix[*PNM.read(intermediate).pixels]]
      else
        fail 'Only grayscale images are supported!'
        # channels = ppm_to_rgb(PPM.read(intermediate))
      end
      %x(rm #{intermediate})
      channels
    end

    def read_image(image_path)
      channels = get_image_channels(image_path)
      @channels = channels.map { |m| Channel.new(m, @num_singular_values) }
      @channels.each(&:decompose)
    end

    def to_image(path)
      if @grayscale
        to_grayscale_image(path)
      else
        fail 'Only grayscale images are supported!'
      end
    end

    def to_grayscale_image(path)
      puts 'writing images...' if @singular_values.length > 1
      @singular_values.each do |sv|
        out_path = extension_swap(path, 'jpg', "_#{sv}_svs")
        intermediate = extension_swap(path, 'pgm', '_tmp_outfile')
        reconstructed_mtrx = @channels.first.reconstruct_matrix(sv)
        cleansed_mtrx = ImageMatrix.matrix_to_valid_pixels(reconstructed_mtrx)
        PNM::Image.new(cleansed_mtrx).write(intermediate)
        %x(convert #{intermediate} #{out_path})
        %x(rm #{intermediate})
      end
    end

    def save_svd(path)
      out_path = extension_swap(path, 'svdim')
      string = @channels.map do |c| {
        'sigma_vTs' => c.sigma_vTs.map(&:to_a),
        'us' => c.us.map(&:to_a),
        'm' => c.m,
        'n' => c.n }
      end.to_json
      File.open(out_path, 'w') do |f|
        f.puts string
      end
    end

    # conforms a matrix to pnm requirements for pixels: positive integers
    # rubocop:disable MethodLength
    def self.matrix_to_valid_pixels(matrix)
      matrix.to_a.map do |row|
        row.map do |number|
          rounded = number.round
          if rounded > 255
            255
          elsif rounded < 0
            0
          else
            rounded
          end
        end
      end
    end

    def self.new_saved_grayscale_svd(opts, h)
      svals = [opts[:singular_values], h['sigma_vTs'].size]
      valid_svals = ImageSvd::Options.num_sing_val_out_from_archive(*svals)
      instance = new(valid_svals, true)
      instance.channels << Channel.new(Matrix[], valid_svals)
      chan = instance.channels.first
      chan.sigma_vTs = h['sigma_vTs']
        .map { |arr| Vector[*arr.flatten].covector }
      chan.us = h['us'].map { |arr| Vector[*arr.flatten] }
      chan.n = h['n']
      chan.m = h['m']
      instance
    end
    # rubocop:enable MethodLength

    # @todo error handling code here
    # @todo serialization is kind of silly as is
    def self.new_from_svd_savefile(opts)
      h = JSON.parse(File.open(opts[:input_file], &:readline))
      if h.length == 1 # grayscale
        new_saved_grayscale_svd(opts, h.first)
      else
        fail 'Only grayscale images are supported!'
      end
    end
  end
  # rubocop:enable SymbolName
  # rubocop:enable VariableName
end
