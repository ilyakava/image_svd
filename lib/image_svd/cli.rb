# encoding: utf-8

module ImageSvd
  # This class is responsible for handling the command line interface
  class CLI
    # The entry point for the application logic
    def run(options)
      Options.iterate_on_input(options) do |o|
        if o[:directory]
          fork { run_single_image(o) }
        else
          run_single_image(o)
        end
      end
      Process.waitall
    end

    # rubocop:disable MethodLength
    def run_single_image(o)
      if o[:read] == true
        app = ImageSvd::ImageMatrix.new_from_svd_savefile(o)
        app.to_image(o[:output_name])
      else
        app = ImageSvd::ImageMatrix.new(o[:singular_values], o[:grayscale])
        app.read_image(o[:input_file])
        if o[:archive] == true
          app.save_svd(o[:output_name])
        elsif o[:convert] == true
          app.to_image(o[:output_name])
        end
      end
    end
  end
  # rubocop:enable MethodLength

  # This module holds custom behavior for dealing with the gem trollop
  module Options
    extend Util

    # rubocop:disable MethodLength
    def self.get
      proc do
        version "Image Svd #{ImageSvd::VERSION} (c) 2014 Ilya Kavalerov"
        banner <<-EOS
          Image Svd is a utilty for compressing images, or creating
          interesting visual effects to distort images when compression is
          set very high. Image Svd performs Singular Value Decomposition
          on any image, grayscale or color.

          Usage:
                 image_svd [options]
          where [options] are:
        EOS
        opt :input_file,
            'An input file (Preferably a jpg). If you also specify'\
            '--directory or -d, you may provide the path to a directory'\
            '(which must end with a "/") instead of a file.',
            type: :io,
            required: true
        opt :grayscale,
            'Do not preserve the colors in the input image.',
            default: true,
            short: '-g'
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
        opt :directory,
            'The input provided is a directory instead of a file.',
            default: false,
            short: '-d'
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
    def self.num_sing_val_out_from_archive(requests, available)
      valid_svals = requests.reject { |v| v > available }
      valid_svals.empty? ? [available] : valid_svals
    end

    def self.process(opts)
      vs = format_num_sing_vals(opts[:num_singular_values].to_s)
      opts.merge(singular_values: vs)
    end

    # reformats the string cmd line option to an array
    def self.format_num_sing_vals(str)
      i, valid_i_regex = [str, /^\d+\.\.\d+$|^\d+$/]
      fail 'invalid --num-singular-values option' unless i.match valid_i_regex
      vs = i.split('..').map(&:to_i)
      vs.length == 1 ? vs : ((vs.first)..(vs.last)).to_a
    end

    # reformats directory inputs into an array of files, or repackages file
    # inputs to be contained inside an array
    def self.expand_input_files(opts)
      if opts[:directory]
        path = opts[:input_file].path
        names = Dir.new(path).to_a
        images = names.select { |name| name =~ Util::VALID_IMAGE_EXT_REGEX }
        images.map { |name| File.new(path + name) }
      else
        [opts[:input_file]]
      end
    end

    # ignore provided output_name in the case that a directory is input
    def self.output_dir_path_for_input_file(dir)
      path_components = dir.path.split('/')
      filename = path_components.pop
      (path_components << 'out' << filename).join('/')
    end

    def self.iterate_on_input(opts)
      %x(mkdir #{opts[:input_file].path + 'out'}) if opts[:directory]
      expand_input_files(opts).each do |file|
        new_options = { input_file: file }
        if opts[:directory]
          new_options.merge!(output_name: output_dir_path_for_input_file(file))
        end
        o = process(opts).merge(new_options)
        yield o
      end
    end
  end
end
