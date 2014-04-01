require 'ffi-ncurses'
require 'azurill/log'

module Azurill
  
  class Colors
    class << self

      def init_colors
        @colors = []

        # define color pairs
        define_color(:RED, :BLACK)
        define_color(:BLACK, :RED)
        define_color(:RED, :RED)
        define_color(:BLACK, :YELLOW)
      end


      def with(c)
        set!(c)
        yield
        reset!
      end

      def set!(c)
        FFI::NCurses.attr_set(FFI::NCurses::A_NORMAL, self.send(c), nil)
      end

      def reset!
        FFI::NCurses.attr_set(FFI::NCurses::A_NORMAL, 0, nil)
      end

      def method_missing(symbol)
        @colors.each_with_index do |c,i|
          #return FFI::NCurses.COLOR_PAIR(i) if c == symbol
          return i+1 if c == symbol
        end
        raise "Couldn't find color: #{symbol}"
      end

      private
      def define_color(foreground, background)
        f = FFI::NCurses::Color.const_get(foreground)
        b = FFI::NCurses::Color.const_get(background)
        Logger.log("blah #{f} #{b}")
        FFI::NCurses.init_pair(@colors.count + 1, f, b)
        @colors << "#{foreground}_on_#{background}".downcase.to_sym
      end
    end
  end
end

Azurill::Colors.init_colors
