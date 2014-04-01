
require 'zmq'
require 'json'

require 'azurill/colors'
require 'azurill/log'
require 'azurill/view'

module Azurill
  
  class Controller

    def initialize
      h, w = FFI::NCurses.getmaxyx(FFI::NCurses.stdscr)

      @main_view = View.new({x: 0, y: 0, w: w, h: h - 2})

      @logs = []

      controller = self
      @main_view.draw do
        # first a line at the top
        FFI::NCurses.clear
        controller.draw_tab_bar('[ session 1 ]')
        controller.draw_status_bar
        # TODO: move to subview
        controller.draw_content
      end

      @fetcher_thread = Thread.new do
        begin
          ctx = ZMQ::Context.new
          socket = ctx.socket(ZMQ::PULL)
          socket.bind('tcp://0.0.0.0:7113')
          Logger.log('Starting ZMQ socket...')
          while (m = socket.recv(ZMQ::NOBLOCK)) || true
            unless m
              sleep(0.1)
              next
            end
            payload = JSON.parse(m)
            level = payload['l'].to_sym
            @main_view.dirty!
            @logs << {m: payload['m'], l: level}
          end
        ensure
          Logger.log('Closing ZMQ.')
          socket.close
          ctx.close
        end
      end

    end

    def draw_tab_bar(t)
      rect = @main_view.rect
      FFI::NCurses.move(rect[:y], rect[:x])
      top_bar = t
      top_bar << (rect[:w] - top_bar.length).times.map {|_| ' ' }.join('')
      FFI::NCurses.attr_set(FFI::NCurses::A_BOLD, Colors.black_on_magenta, nil)
      FFI::NCurses.addstr(top_bar)
      Colors.reset!
    end

    def draw_status_bar
      rect = @main_view.rect
      FFI::NCurses.move(rect[:h] + 1, rect[:x])
      top_bar_left = ' ***'
      top_bar_right = '*** '
      top_bar_middle = (rect[:w] - top_bar_left.length - top_bar_right.length).times.map {|_| ' ' }.join('')
      top_bar = top_bar_left + top_bar_middle + top_bar_right
      FFI::NCurses.attr_set(FFI::NCurses::A_BOLD, Colors.black_on_magenta, nil)
      FFI::NCurses.addstr(top_bar)
      Colors.reset!
    end

    def draw_content
      rect = @main_view.rect
      i = 1
      @logs.each do |e|
        color = case e[:l]
                when :verbose; :nocolor
                when :info; :cyan_on_black
                when :warn; :yellow_on_black
                when :error; :red_on_black
                end
        char = case e[:l]
               when :verbose; 'V'
               when :info; 'I'
               when :warn; 'W'
               when :error; 'E'
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
