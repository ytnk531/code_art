require 'gdk_pixbuf2'
require 'numo/narray'
require 'base64'

class Generator
  CODE_TEMPLATE = -> (message) { "eval(%w(puts(\"#{message}\".unpack('m')\[0\]))*\"\")" }

  def initialize(image_path, message, threshold, reverse = false)
    @image_path = image_path
    @message = message
    @reverse = reverse
    @threshold = threshold || 120
  end

  def val_to_plot
    @reverse ? 0 : 1
  end

  def run
    shape = binarize(image_narray)
    dots = shape.flatten.count { _1 == val_to_plot }

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

  def binarize(narray)
    narray.to_a.map do |row|
      row.map do |r, g, b,a|
        plotted = a != 0 && (r + g + b) / 3  < @threshold
        plotted ? 1 : 0
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
      row.map do |val|
        if val == val_to_plot
          chars.pop
        else
          " "
        end
      end.join
    end.join("\n")
  end
end

args = ARGV.dup
reverse = !!args.delete('--reverse')

Generator.new(args[0], args[1], args[2]&.to_i, reverse).run
