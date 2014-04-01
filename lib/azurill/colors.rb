require 'ffi-ncurses'
require 'azurill/log'

module Azurill
  
  class Colors
    class << self

      def init_colors
        return if @colors
        @colors = []

        # define color pairs
        define_color(:RED, :BLACK)
        define_color(:YELLOW, :BLACK)
        define_color(:CYAN, :BLACK)
        define_color(:BLACK, :MAGENTA)
      end


      def with(c)
        set!(c)
        yield
        reset!
      end

      def set!(c)
        init_colors
        FFI::NCurses.attr_set(FFI::NCurses::A_NORMAL, self.send(c), nil)
      end

      def reset!
        FFI::NCurses.attr_set(FFI::NCurses::A_NORMAL, 0, nil)
      end

      def nocolor
        0
      end

      def method_missing(symbol)
        init_colors
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
        FFI::NCurses.init_pair(@colors.count + 1, f, b)
        @colors << "#{foreground}_on_#{background}".downcase.to_sym
      end
    end
  end
end
