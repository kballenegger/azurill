
require 'azurill/colors'
require 'azurill/view'

module Azurill
  
  class Controller

    def initialize
      h, w = FFI::NCurses.getmaxyx(FFI::NCurses.stdscr)

      @main_view = View.new({x: 0, y: 1, w: w, h: h - 2})

      @buffer = []

      controller = self
      @main_view.draw do
        # first a line at the top
        FFI::NCurses.clear
        FFI::NCurses.move(rect[:y], rect[:x])
        str = rect[:w].times.map {|_| '-' }.join('')
        FFI::NCurses.addstr(str)
        # TODO: move to subview
        i = 1
        controller.instance_variable_get(:@buffer).each do |e|
          lines = e.split("\n") # TODO: split on lines that are too long...
          # draw label
          FFI::NCurses.move(rect[:y] + i, rect[:x])
          Colors.with(:red_on_black) do
            FFI::NCurses.addch('W'.ord)
          end
          lines.each_with_index do |l,j|
            FFI::NCurses.move(rect[:y] + i + j, rect[:x] + 2)
            Colors.with(:black_on_red) do
              FFI::NCurses.addch('|'.ord)
            end
            FFI::NCurses.move(rect[:y] + i + j, rect[:x] + 4)
            FFI::NCurses.addstr(l)
          end
          i += lines.count + 1
        end
      end

      @fetcher_thread = Thread.new do
        while true
          sleep(1)
          @main_view.dirty!
          str = "Hello world random #{rand(50)}..."
          rand(5).times { str << "\nline!"}
          @buffer << str
        end
      end

    end

    def handle_char(c)
      case c
      when 'q'.ord
        Application.current.next do
          Thread.kill(@fetcher_thread)
          Application.exit!
        end
      when 'c'.ord
        @main_view.dirty!
        @buffer = []
      else
        @main_view.dirty!
        @buffer << "Hello!"
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
