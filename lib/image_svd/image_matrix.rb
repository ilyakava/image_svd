require 'matrix'
require 'json'
require 'pnm'

module ImageSvd
  # This class is responsible for almost everything :(
  # Reading an image or archive to a matrix
  # Saving a matrix to an image
  # Performing Singular Value Decomposition on a matrix
  class ImageMatrix
    # rubocop:disable SymbolName
    # rubocop:disable VariableName
    attr_reader :num_singular_values
    attr_accessor :sigma_vTs, :us, :m, :n

    def initialize(num_singular_values)
      @num_singular_values = num_singular_values
    end

    def read_image(image_path)
      intermediate = extension_swap(image_path.path, 'pgm')
      %x(convert #{image_path.path} #{intermediate})
      image = PNM.read intermediate
      decompose Matrix[*image.pixels]
      %x(rm #{intermediate})
      self
    end

    # @todo abstract this to another class
    def extension_swap(path, new_ext, suffix = '')
      path.gsub(/\..{1,5}$/, "#{suffix}.#{new_ext}")
    end

    # The most time consuming method
    # Launches the decomposition and saves the two lists
    # of vectors needed to reconstruct the image
    # rubocop:disable MethodLength
    def decompose(m_A)
      m_AT = m_A.transpose
      m_ATA = m_AT * m_A
      dcmp = Matrix::EigenvalueDecomposition.new(m_ATA)
      evs = dcmp.eigenvalues
      # eigenvectors are already normalized and in same order as eigenvalues
      sorted_eigenvectors = dcmp.eigenvectors.each_with_index
        .sort_by { |_v, i| -evs[i] }
        .map { |v, _idx| v }
      @m, @n = m_A.to_a.length, m_A.to_a.first.length
      both = (0...@num_singular_values).map do |idx|
        u = sorted_eigenvectors[idx]
        sigma_vT = (m_A * u).covector
        [u, sigma_vT]
      end
      @sigma_vTs = both.map { |p| p.last }
      @us = both.map { |p| p.first }
    end
    # rubocop:enable MethodLength

    def reconstruct_matrix
      zero_matrix = Matrix[*Array.new(@n) { Array.new(@m) { 0 } }]
      (0...@num_singular_values).reduce(zero_matrix) do |acc, idx|
        acc + (@us[idx] * @sigma_vTs[idx])
      end.transpose
    end

    def to_image(path)
      out_path = extension_swap(path, 'jpg')
      intermediate = extension_swap(path, 'pgm', '_tmp_outfile')
      cleansed_matrix = matrix_to_valid_pixels(reconstruct_matrix)
      PNM::Image.new(cleansed_matrix).write(intermediate)
      %x(convert #{intermediate} #{out_path})
      %x(rm #{intermediate})
      true
    end

    # conforms a matrix to pnm requirements for pixels: positive integers
    # rubocop:disable MethodLength
    def matrix_to_valid_pixels(matrix)
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

    def save_svd(path)
      out_path = extension_swap(path, 'svdim')
      string = {
        'sigma_vTs' => @sigma_vTs.map(&:to_a),
        'us' => @us.map(&:to_a),
        'm' => @m,
        'n' => @n
      }.to_json
      File.open(out_path, 'w') do |f|
        f.puts string
      end
    end

    # @todo error handling code here
    # @todo serialization is kind of silly as is
    def self.new_from_svd_savefile(path)
      h = JSON.parse(File.open(path, &:readline))
      instance = new(h['sigma_vTs'].length)
      instance.sigma_vTs = h['sigma_vTs']
        .map { |arr| Vector[*arr.flatten].covector }
      instance.us = h['us'].map { |arr| Vector[*arr.flatten] }
      instance.n = h['n']
      instance.m = h['m']
      instance
    end
    # rubocop:enable SymbolName
    # rubocop:enable VariableName
  end
end
