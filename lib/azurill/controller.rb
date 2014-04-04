
require 'zmq'
require 'json'

require 'azurill/colors'
require 'azurill/log'
require 'azurill/view'

module Azurill
  
  class Controller

    def initialize
      h, w = FFI::NCurses.getmaxyx(FFI::NCurses.stdscr)

      @main_view = View.new()
      size(w, h)

      controller = self
      @main_view.draw do
        # first a line at the top
        FFI::NCurses.clear
        controller.draw_tab_bar('[ session 1 ]')
        controller.draw_status_bar
        # TODO: move to subview
        controller.draw_scrollbar
        controller.draw_content
      end

      start_zmq_reader
      initialize_values
    end

    def start_zmq_reader
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
            log({m: payload['m'], l: level})
          end
        ensure
          Logger.log('Closing ZMQ.')
          ctx.close
        end
      end
    end

    def initialize_values
      @logs = []
      @processed_logs = []

      @selected = nil
      @offset = 0
      @expand = true
      @tailing = true
      @anchor = :bottom
    end

    def draw_tab_bar(t)
      rect = @main_view.rect
      FFI::NCurses.move(rect[:y]-1, rect[:x])
      top_bar = t
      top_bar << (rect[:w] + 1 - top_bar.length).times.map {|_| ' ' }.join('')
      Colors.with(:white_on_800040) do
        FFI::NCurses.addstr(top_bar)
      end
    end

    def draw_status_bar
      rect = @main_view.rect
      FFI::NCurses.move(rect[:h] + 1, rect[:x])
      top_bar_left = ' ***'
      top_bar_right = '*** '
      top_bar_middle = (rect[:w] + 1 - top_bar_left.length - top_bar_right.length).times.map {|_| ' ' }.join('')
      top_bar = top_bar_left + top_bar_middle + top_bar_right
      Colors.with(:white_on_800040) do
        FFI::NCurses.addstr(top_bar)
      end
    end

    def draw_scrollbar
      rect = @main_view.rect
      0.upto(rect[:h]-1) do |i|
        FFI::NCurses.move(rect[:y] + i, rect[:x] + rect[:w])
        pair = i < 5 ? :black_on_636363 : :black_on_3f3f3f
        Colors.with(pair) do
          FFI::NCurses.addch(' '.ord)
        end
      end
    end

    def draw_content
      rect = @main_view.rect
      i = 0
      @processed_logs.each_with_index do |e, index|
        char = e[:char]
        color = e[:color]
        lines = e[:lines]
        bg = @selected.is_a?(Integer) && index == @selected ? '1a1a1a' : 'black'
        pair = "#{color}_on_#{bg}".to_sym
        # draw label
        lines.each_with_index do |l,j|
          point = point_in_parent(rect[:y] + i + j - @offset, rect[:x])
          next unless in_rect(*point)
          # draw background
          FFI::NCurses.move(*point)
          Colors.with("white_on_#{bg}".to_sym) do
            bgstr = rect[:w].times.map {|_| ' ' }.join
            FFI::NCurses.addstr(bgstr)
          end
          # draw line
          point = point_in_parent(rect[:y] + i + j - @offset, rect[:x] + 2)
          FFI::NCurses.move(*point)
          Colors.with(pair) do
            FFI::NCurses.addch('|'.ord)
          end
          # draw text
          FFI::NCurses.move(*point_in_parent(rect[:y] + i + j - @offset, rect[:x] + 4))
          Colors.with("white_on_#{bg}".to_sym) do
            FFI::NCurses.addstr(l)
          end
        end
        point = point_in_parent(rect[:y] + i - @offset, rect[:x])
        if in_rect(*point)
          FFI::NCurses.move(*point)
          Colors.with(pair) do
            FFI::NCurses.addch(char.ord)
          end
        end
        i += lines.count + 1
      end
    end

    def log(payload)
      @logs << payload
      @processed_logs << processed_log(payload)
      if @tailing
        bottom
      else
        snap_to_anchor
      end
    end

    def process_logs
      @processed_logs = @logs.map do |e|
        processed_log(e)
      end
    end

    def processed_log(e)
      rect = @main_view.rect
      max_len = rect[:w] - 4
      color = case e[:l]
              when :verbose; :dddddd
              when :info; :cyan
              when :warn; :yellow
              when :error; :red
              end
      char = case e[:l]
             when :verbose; 'V'
             when :info; 'I'
             when :warn; 'W'
             when :error; 'E'
             end

      lines = e[:m].split("\n").map do |l|
        l.scan(/.{1,#{max_len}}/)
      end.flatten
      unless @expand
        old_lines_count = lines.length
        lines = lines.first(3)
        lines << '...' if lines.length < old_lines_count
      end

      {
        color: color,
        char: char,
        lines: lines,
        line_count: lines.length,
      }
    end

    # y, x
    def point_in_parent(y,x)
      [
        y + @main_view.rect[:y],
        x + @main_view.rect[:x]
      ]
    end

    # y, x
    def in_rect(y,x)
      w, h = @main_view.rect[:w], @main_view.rect[:h]
      ox, oy = @main_view.rect[:x], @main_view.rect[:y]
      x < w + ox && x >= ox && y < h + oy && y >= oy
    end

    def size(w,h)
      @main_view.rect = {x: 0, y: 1, w: w - 1, h: h - 2}
    end

    def snap_to_anchor
      case @anchor
      when :bottom
        bottom
      when :top
        @offset = 0
        @main_view.dirty!
      when Hash
        # for now, a Hash means that it's a log item, with the following
        # format: 
        #   {
        #     offset: Numeric # where on screen that offset starts
        #     log: Numeric # the index of the log to anchor
        #   }
        index, offset = @anchor[:log], @anchor[:offset]
        before = @processed_logs.first(index)
        @offset = before.map {|e| e[:line_count] + 1 }.reduce(&:+) || 0
        @offset += offset
        @main_view.dirty!
      end
    end

    def anchor_to_top_log
      @tailing = false
      heights = @processed_logs.map {|e| e[:line_count] + 1 }
      # find the first that's on screen right now
      i, sum = 0, 0
      i, sum = i+1, sum + heights[i] while sum < @offset && heights[i]
      return if i > heights.length # FIXME
      @anchor = {
        log: i,
        offset: @offset - sum - heights[i-1] + 2,
        # i have no idea why we need to +2 here. fuck.
      }
      Logger.log("Anchoring to #{@anchor}")
    end

    def handle_char(c)
      case c
      when 'q'.ord
        Application.current.next do
          Thread.kill(@fetcher_thread)
          Application.exit!
        end
      when 'c'.ord
        initialize_values
        @main_view.dirty!
      when 'd'.ord
        page_down
      when 'u'.ord
        page_up
      when 'T'.ord
        tailing(false)
      when 't'.ord
        tailing(true)
        bottom
      when 'E'.ord
        expand(false)
      when 'e'.ord
        expand(true)
      when 'g'.ord
        @offset = 0
        @anchor = :top
        @main_view.dirty!
      when 'G'.ord
        bottom
        @anchor = :bottom
      when 27 # ESC
        @selected = nil
        @main_view.dirty!
      else
        @main_view.dirty!
        log({m: 'Hello!', l: :verbose})
      end
    end

    def page_down
      @offset = [@offset - 5, 0].max
      anchor_to_top_log
      @main_view.dirty!
    end

    def page_up
      total_lines = @processed_logs.map {|e| e[:line_count] + 1 }.reduce(&:+)
      min_offset = total_lines - @main_view.rect[:h]
      @offset =  total_lines < @main_view.rect[:h] ? 0 : [@offset + 5, min_offset].min
      anchor_to_top_log
      @main_view.dirty!
    end

    def bottom
      total_lines = @processed_logs.length + (@processed_logs.map {|l|l[:line_count]}.reduce(&:+) || 0)
      @offset = total_lines - @main_view.rect[:h]
      @offset = 0 if total_lines < @main_view.rect[:h]
      @main_view.dirty!
    end

    def expand(bool)
      @expand = bool
      process_logs
      snap_to_anchor
      @main_view.dirty!
    end

    def tailing(bool)
      @tailing = bool
    end

    def draw
      @main_view.draw
    end

    def close!
      # TODO close any other threads
    end
  end
end
