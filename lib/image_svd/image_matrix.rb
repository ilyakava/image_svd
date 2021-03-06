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

    # returns all the information necessary to serialize this channel
    def to_h
      {
        'sigma_vTs' => @sigma_vTs.map(&:to_a),
        'us' => @us.map(&:to_a),
        'm' => @m,
        'n' => @n
      }
    end

    # can initialize with the result of #to_h
    def self.apply_h(hash, num_singular_values)
      c = new(Matrix[], num_singular_values)
      c.sigma_vTs = hash['sigma_vTs']
        .map { |arr| Vector[*arr.flatten].covector }
      c.us = hash['us'].map { |arr| Vector[*arr.flatten] }
      c.m = hash['m']
      c.n = hash['n']
      c
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
      extension = @grayscale ? 'pgm' : 'ppm'
      intermediate = extension_swap(image_path.path, extension)
      %x(convert #{image_path.path} #{intermediate})
      if @grayscale
        channels = [PNM.read(intermediate).pixels]
      else
        channels = ImageMatrix.ppm_to_rgb(PNM.read(intermediate).pixels)
      end
      %x(rm #{intermediate})
      channels.map { |c| Matrix[*c] }
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
        to_color_image(path)
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
        add_image_svd_credit!(out_path)
        %x(rm #{intermediate})
      end
    end

    def to_color_image(path)
      puts 'writing images...' if @singular_values.length > 1
      @singular_values.each do |sv|
        out_path = extension_swap(path, 'jpg', "_#{sv}_svs")
        intermediate = extension_swap(path, 'ppm', '_tmp_outfile')
        ms = @channels.map { |c| c.reconstruct_matrix(sv) }
        cleansed_mtrxs = ms.map { |m| ImageMatrix.matrix_to_valid_pixels(m) }
        ppm_matrix = ImageMatrix.rgb_to_ppm(*cleansed_mtrxs)
        PNM::Image.new(ppm_matrix).write(intermediate)
        %x(convert #{intermediate} #{out_path})
        add_image_svd_credit!(out_path)
        %x(rm #{intermediate})
      end
    end

    # more info: http://www.imagemagick.org/Usage/formats/#profile_iptc
    def add_image_svd_credit!(path)
      r = rand(99999)
      %x(echo '#{Util::IMAGE_CREDIT}' > iptcData#{r}.pro)
      %x(convert #{path} +profile 8BIM -profile 8BIMTEXT:iptcData#{r}.pro #{path})
      %x(rm iptcData#{r}.pro)
    end

    def save_svd(path)
      out_path = extension_swap(path, 'svdim')
      string = @channels.map(&:to_h).to_json
      File.open(out_path, 'w') do |f|
        f.puts string
      end
    end

    # breaks a ppm image into 3 separate channels
    def self.ppm_to_rgb(arr)
      (0..2).to_a.map do |i|
        arr.map { |row| row.map { |pix| pix[i] } }
      end
    end

    # combines 3 separate channels into the ppm scheme
    def self.rgb_to_ppm(r, g, b)
      r.each_with_index.map do |row, row_i|
        row.each_with_index.map do |_, pix_i|
          [r[row_i][pix_i], g[row_i][pix_i], b[row_i][pix_i]]
        end
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
    # rubocop:enable MethodLength

    def self.new_saved_grayscale_svd(opts, h)
      svals = [opts[:singular_values], h['sigma_vTs'].size]
      valid_svals = ImageSvd::Options.num_sing_val_out_from_archive(*svals)
      instance = new(valid_svals, true)
      instance.channels << Channel.apply_h(h, valid_svals)
      instance
    end

    def self.new_saved_color_svd(opts, hs)
      svals = [opts[:singular_values], hs.first['sigma_vTs'].size]
      valid_svals = ImageSvd::Options.num_sing_val_out_from_archive(*svals)
      instance = new(valid_svals, false)
      3.times do |i|
        chan = Channel.apply_h(hs[i], valid_svals)
        instance.channels << chan
      end
      instance
    end

    # @todo error handling code here
    # @todo serialization is kind of silly as is
    def self.new_from_svd_savefile(opts)
      h = JSON.parse(File.open(opts[:input_file], &:readline))
      if h.length == 1 # grayscale
        new_saved_grayscale_svd(opts, h.first)
      else
        new_saved_color_svd(opts, h)
      end
    end
  end
  # rubocop:enable SymbolName
  # rubocop:enable VariableName
end
