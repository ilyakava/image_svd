# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'image_svd/version'

Gem::Specification.new do |spec|
  spec.name          = 'image_svd'
  spec.version       = ImageSvd::VERSION
  spec.authors       = ['Ilya Kavalerov']
  spec.email         = ['ilya@artsymail.com']
  spec.summary       = 'Compress images with Linear Algebra.'
  spec.description   = <<-EOF
    Break down grayscale image matricies into their
    singular value decomposition. Space saving, but CPU intensive.
  EOF
  spec.homepage      = 'https://github.com/ilyakava/image_svd'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(/^bin\//) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(/^(test|spec|features)\//)
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'pnm'
  spec.add_runtime_dependency 'trollop', '~> 2.0'
  spec.add_development_dependency 'bundler', '~> 1.5'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rspec'
end
