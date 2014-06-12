module ImageSvd
  # This module holds useful miscellaneous methods
  module Util
    # rubocop:disable LineLength
    # imagemagick supported formats from running `convert -list format`
    VALID_IMAGE_EXT_REGEX = /\.3FR|\.A|\.AAI|\.AI|\.ART|\.ARW|\.AVI|\.AVS|\.B|\.BGR|\.BGRA|\.BMP|\.BMP2|\.BMP3|\.BRF|\.C|\.CAL|\.CALS|\.CANVAS|\.CAPTION|\.CIN|\.CIP|\.CLIP|\.CMYK|\.CMYKA|\.CR2|\.CRW|\.CUR|\.CUT|\.DCM|\.DCR|\.DCX|\.DDS|\.DFONT|\.DNG|\.DOT|\.DPX|\.DXT1|\.DXT5|\.EPDF|\.EPI|\.EPS|\.EPS2|\.EPS3|\.EPSF|\.EPSI|\.ERF|\.FAX|\.FITS|\.FRACTAL|\.FTS|\.G|\.G3|\.GIF|\.GIF87|\.GRADIENT|\.GRAY|\.GV|\.HALD|\.HDR|\.HISTOGRAM|\.HRZ|\.HTM|\.HTML|\.ICB|\.ICO|\.ICON|\.INFO|\.INLINE|\.IPL|\.ISOBRL|\.JNG|\.JNX|\.JPEG|\.JPG|\.K|\.K25|\.KDC|\.LABEL|\.M|\.M2V|\.M4V|\.MAC|\.MAP|\.MASK|\.MAT|\.MATTE|\.MEF|\.MIFF|\.MNG|\.MONO|\.MOV|\.MP4|\.MPC|\.MPEG|\.MPG|\.MRW|\.MSL|\.MSVG|\.MTV|\.MVG|\.NEF|\.NRW|\.NULL|\.O|\.ORF|\.OTB|\.OTF|\.PAL|\.PALM|\.PAM|\.PANGO|\.PATTERN|\.PBM|\.PCD|\.PCDS|\.PCL|\.PCT|\.PCX|\.PDB|\.PDF|\.PDFA|\.PEF|\.PES|\.PFA|\.PFB|\.PFM|\.PGM|\.PICON|\.PICT|\.PIX|\.PJPEG|\.PLASMA|\.PNG|\.PNG00|\.PNG24|\.PNG32|\.PNG48|\.PNG64|\.PNG8|\.PNM|\.PPM|\.PREVIEW|\.PS|\.PS2|\.PS3|\.PSB|\.PSD|\.PWP|\.R|\.RAF|\.RAS|\.RGB|\.RGBA|\.RGBO|\.RGF|\.RLA|\.RLE|\.RW2|\.SCR|\.SCT|\.SFW|\.SGI|\.SHTML|\.SPARSE|\.SR2|\.SRF|\.STEGANO|\.SUN|\.SVG|\.SVGZ|\.TEXT|\.TGA|\.THUMBNAIL|\.TILE|\.TIM|\.TTC|\.TTF|\.TXT|\.UBRL|\.UIL|\.UYVY|\.VDA|\.VICAR|\.VID|\.VIFF|\.VST|\.WBMP|\.WMV|\.WPG|\.X3F|\.XBM|\.XC|\.XCF|\.XPM|\.XPS|\.XV|\.Y|\.YCbCr|\.YCbCrA|\.YUV/i
    # rubocop:enable LineLength

    # always place the new extension, even if there is nothing to swap out
    def extension_swap(path, new_ext, suffix = '')
      head = path.gsub(/\..{1,5}$/, '')
      "#{head}#{suffix}.#{new_ext}"
    end
  end
end
