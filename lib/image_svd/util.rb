module ImageSvd
  # This module holds useful miscellaneous methods
  module Util
    # always place the new extension, even if there is nothing to swap out
    def extension_swap(path, new_ext, suffix = '')
      head = path.gsub(/\..{1,5}$/, '')
      "#{head}#{suffix}.#{new_ext}"
    end
  end
end
