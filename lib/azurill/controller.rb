
require 'azurill/colors'
require 'azurill/view'

module Azurill
  
  class Controller

    def initialize
      h, w = FFI::NCurses.getmaxyx(FFI::NCurses.stdscr)

      @main_view = View.new({x: 0, y: 0, w: w, h: h - 1})

      @logs = []

      controller = self
      @main_view.draw do
        # first a line at the top
        FFI::NCurses.clear
        FFI::NCurses.move(rect[:y], rect[:x])
        top_bar = '[ session 1 ]'
        top_bar << (rect[:w] - top_bar.length).times.map {|_| ' ' }.join('')
        FFI::NCurses.attr_set(FFI::NCurses::A_BOLD, Colors.black_on_magenta, nil)
        FFI::NCurses.addstr(top_bar)
        Colors.reset!
        # TODO: move to subview
        i = 1
        controller.instance_variable_get(:@logs).each do |e|
          color = case e[:l]
                  when :verbose; :nocolor
                  when :info; :cyan_on_black
                  when :warn; :yellow_on_black
                  when :err; :red_on_black
                  end
          char = case e[:l]
                 when :verbose; 'V'
                 when :info; 'I'
                 when :warn; 'W'
                 when :err; 'E'
                 end

          lines = e[:m].split("\n") # TODO: split on lines that are too long...
          # draw label
          FFI::NCurses.move(rect[:y] + i, rect[:x])
          Colors.with(color) do
            FFI::NCurses.addch(char.ord)
          end
          lines.each_with_index do |l,j|
            FFI::NCurses.move(rect[:y] + i + j, rect[:x] + 2)
            Colors.with(color) do
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
          @logs << {m: str, l: [:warn, :info, :err, :verbose].sample}
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
        @logs = []
      else
        @main_view.dirty!
        @logs << {m: 'Hello!', l: :verbose}
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
