require 'gdk_pixbuf2'
require 'numo/narray'
require 'base64'

class Generator
  CODE_TEMPLATE = -> (message) { "eval(%w(puts \"#{message}\".unpack('m')\[0\])*\"\")" }

  def initialize(image_path, message)
    @image_path = image_path
    @message = message
  end
  
  def run
    shape = normarize(image_narray)
    dots = shape.flatten.sum

    puts code_art(encoded_message_print_code(@message, dots), shape)
  end

  def image_narray
    image  = GdkPixbuf::Pixbuf.new(file: @image_path)
    width  = image.width
    height = image.height
    
    pixel_data = image.pixel_bytes.to_str
    
    narray = Numo::UInt8.from_binary pixel_data
    narray.reshape!(height, width, 4)
  end

  def normarize(narray)
    narray.to_a.map do |row|
      row.map do |r,g,b,a|
        if a != 0 && (r + g + b) / 3  < 200
          0
        else
          1
        end
      end
    end
  end

  def encoded_message_print_code(text, limit)
    available_length = limit - CODE_TEMPLATE.call("").length
    encoded_text = [text].pack("m").gsub("\n", '')
    repeated_text = encoded_text.chars
                                .cycle
                                .first(available_length)
                                .join

    CODE_TEMPLATE.call(repeated_text)
  end

  def code_art(code, shape)
    chars = code.chars.reverse

    shape.map do |row|
      row.map do |c|
        if c == 1
          chars.pop
        else
          " "
        end
      end.join
    end.join("\n")
  end
end

Generator.new(ARGV[0], ARGV[1]).run
