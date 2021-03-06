require 'ffi-ncurses'

require 'azurill/log'
require 'azurill/version'
require 'azurill/controller'

module Azurill

  class Application

    # Start the application!
    #
    def self.start!
      # create application instance
      @current = self.new
      @current.run!
    ensure
      @current.close!
    end

    # Exits.
    #
    def self.exit!
      throw :exit
    end

    # Global shared application.
    #
    def self.current
      @current
    end


    # -- actual implementation

    # Create the application, this initializes ncurses, but does not yet do
    # anything. Call the `run!` method to start the run loop.
    #
    def initialize
      FFI::NCurses.initscr
      #FFI::NCurses.start_color
      FFI::NCurses.curs_set(0)
      FFI::NCurses.nodelay(FFI::NCurses.stdscr, true)
      FFI::NCurses.cbreak
      FFI::NCurses.raw
      FFI::NCurses.noecho
      FFI::NCurses.start_color
      FFI::NCurses.clear
    end

    # This creates and starts the run loop, this is the root method of the
    # entire application's lifetime.
    #
    def run!
      @queue = []
      queue do
        @controller = Controller.new
      end
      catch :exit do
        while true
          tick
          FFI::NCurses.refresh
        end
      end
    rescue Exception => e
      Logger.log(e.message)
      Logger.log(e.backtrace.join("\n"))
      FFI::NCurses.clear
      FFI::NCurses.endwin
      raise
    end

    # This closes the app, and clears the app from the terminal.
    #
    def close!
      @controller.close! if @controller
      FFI::NCurses.endwin
      Process.exit!
    end

    # This method gets executed for every iteration of the run loop.
    #
    def tick
      unless @queue.empty?
        @queue.shift.call
      else
        unless (c = FFI::NCurses.getch) == FFI::NCurses::ERR
          @controller.handle_char(c)
        else
          sleep(0.1)
        end
      end
      h, w = FFI::NCurses.getmaxyx(FFI::NCurses.stdscr)
      @controller.size(w,h)
      @controller.draw
    end

    # Queue a block for the next available tick.
    #
    def queue(&b)
      @queue << b
    end
    def next(&b)
      @queue.unshift(b)
    end
  end
end
