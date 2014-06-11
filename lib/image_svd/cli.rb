# encoding: utf-8

module ImageSvd
  # This class is responsible for handling the command line interface
  class CLI
    # The entry point for the application logic
    # rubocop:disable MethodLength
    def run(opts)
      opts = process_options(opts)
      if opts[:read] == true
        app = ImageSvd::ImageMatrix.new_from_svd_savefile(opts)
        app.to_image(opts[:output_name])
      else
        app = ImageSvd::ImageMatrix.new(opts[:singular_values])
        app.read_image(opts[:input_file])
        if opts[:archive] == true
          app.save_svd(opts[:output_name])
        elsif opts[:convert] == true
          app.to_image(opts[:output_name])
        end
      end
    end

    def process_options(opts)
      i, valid_i = [opts[:num_singular_values].to_s, /^\d+\.\.\d+$|^\d+$/]
      fail 'invalid --num-singular-values option' unless i.match valid_i
      vs = i.split('..').map(&:to_i)
      vs = (vs.length == 1 ? vs : ((vs.first)..(vs.last)).to_a)
      opts.merge(singular_values: vs)
    end
  end
  # rubocop:enable MethodLength

  # This module holds custom behavior for dealing with the gem trollop
  module Options
    # rubocop:disable MethodLength
    def self.get
      proc do
        version "Image Svd #{ImageSvd::VERSION} (c) 2014 Ilya Kavalerov"
        banner <<-EOS
          Image Svd is a utilty that performs Singular Value Decomposition
          on a grayscale image. It can be useful for compressing images, or
          creating interesting visual effects to distort images when
          compression is set very high.

          Usage:
                 image_svd [options]
          where [options] are:
        EOS
        opt :input_file,
            'An input file (Preferably a jpg).',
            type: :io,
            required: true
        opt :num_singular_values,
            'The number of singular values to keep for an image. Lower'\
              ' numbers mean lossier compression; smaller files and more'\
              ' distorted images. You may also provide a range ruby style,'\
              ' (ex: 1..9) in which case many images will be output.',
            default: '50',
            short: '-n'
        opt :output_name,
            'A path/name for an output file (Extension will be ignored).'\
              ' If no path/name is provided, a file will be written in'\
              ' the current directory',
            default: 'svd_image_output',
            short: '-o'
        opt :convert,
            'Convert the input file now.',
            default: true,
            short: '-c'
        opt :archive,
            'Save the Image Svd archive without converting the input image.',
            default: false,
            short: '-a'
        opt :read,
            'Read an Image Svd archive (*.svdim) and output the image'\
              ' it contains.',
            default: false,
            short: '-r'
      end
    end
    # rubocop:enable MethodLength

    # this method chooses which number of singular values are valid to output
    # to an image file from an archive file provided. @returns Array[Int]
    def self.numSingValsToOutputFromArchive(requests, available)
      valid_svals = requests.reject { |v| v > available }
      valid_svals.empty? ? [available] : valid_svals
    end
  end
end
