
require 'azurill/view'

module Azurill
  
  class Controller

    def initialize
      h, w = FFI::NCurses.getmaxyx(FFI::NCurses.stdscr)

      @main_view = View.new({x: 0, y: 1, w: w, h: h - 2})

      @main_view.draw do
        # first a line at the top
        str = rect[:w].times.map {|_| '-' }.join('')
        FFI::NCurses.addstr(str)
        FFI::NCurses.addstr("Hello world #{h}\n")
      end

    end

    def handle_char(c)
      case c
      when 'q'.ord
        Application.current.next do
          Application.exit!
        end
      else
        Application.current.queue do
          FFI::NCurses.addstr("Hello!\n")
        end
      end
    end

    def draw
      @main_view.draw
    end

    def close!
      # TODO close any other threads
    end
  end
end
