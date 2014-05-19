# encoding: utf-8

$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../lib')
require 'image_svd'
require 'pry'

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
end
