
require 'azurill/colors'

module Azurill

  class CommandBarWindow

    # Must be initialized with a rect and a completion block:
    #
    # Options include :prompt and :color.
    #
    # Height must be 1.
    #
    # When the user presses ESC, the input is cancelled and the callback is
    # passed nil.
    #
    #   CommandBarWindow.new(rect, prompt: '$') do |string|
    #     Logger.log("Input was #{string}")
    #   end
    #
    def initialize(rect, opts={}, &block)
      @buffer = ''
      @rect = rect
      @index = 0
      @opts = {
        prompt: '',
        color: :black_on_white,
      }.merge(opts)
      @complete_block = block
      @old_curs = FFI::NCurses.curs_set(2)
    end

    def handle_char(c)
      if c >= 32 && c <= 126 # printable characters
        @buffer.insert(@index, c.chr)
        @index += 1
      elsif c == 10 # enter / CR
        handle_enter
      elsif c == 27
        handle_esc
      end
      # TODO: left and right arrows
    end

    def handle_enter
      FFI::NCurses.curs_set(@old_curs)
      @complete_block.call(@buffer)
    end

    def handle_esc
      FFI::NCurses.curs_set(@old_curs)
      @complete_block.call(nil)
    end

    def draw
      rect = @rect
      FFI::NCurses.move(rect[:y], rect[:x])
      bar_content = @opts[:prompt] + @buffer
      bar_content << (@rect[:w] - bar_content.length).times.map{' '}.join if bar_content.length < @rect[:w]
      bar_content = bar_content.chars.last(rect[:w]).join
      Colors.with(@opts[:color]) do
        FFI::NCurses.addstr(bar_content)
      end
      move_to_cursor
    end

    def move_to_cursor
      FFI::NCurses.move(@rect[:y], @rect[:x] + @opts[:prompt].length + @index)
    end
  end
end
