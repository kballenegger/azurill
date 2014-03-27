require 'azurill/version'
require 'ffi-ncurses'

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
      FFI::NCurses.clear
    end

    # This creates and starts the run loop, this is the root method of the
    # entire application's lifetime.
    #
    def run!
      @queue = []
      @controller = Controller.new(self)
      catch :exit do
        while true
          tick
          FFI::NCurses.refresh
        end
      end
    end

    # This closes the app, and clears the app from the terminal.
    #
    def close!
      @controller.close!
      FFI::NCurses.endwin
    end

    # This method gets executed for every iteration of the run loop.
    #
    def tick
      unless queue.empty?
        @queue.pop.call
      else
        # TODO: event handling
        FFI::NCurses.getch
      end
    end

    # Queue a block for the next available tick.
    #
    def queue(&b)
      @queue << b
    end
  end
end
