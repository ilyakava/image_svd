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
    Break down images into their singular value decomposition.
  EOF
  spec.homepage      = 'https://github.com/ilyakava/image_svd'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(/^bin\//) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(/^(test|spec|features)\//)
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'pnm', '~> 0.3'
  spec.add_runtime_dependency 'trollop', '~> 2.0'
  spec.add_development_dependency 'bundler', '~> 1.5'
  spec.add_development_dependency 'rake', '~> 10.3'
  spec.add_development_dependency 'pry', '~> 0.9'
  spec.add_development_dependency 'rspec', '~> 2.14'
end
