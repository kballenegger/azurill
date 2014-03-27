
module Azurill
  
  class Controller

    def initialize
      # :)
      FFI::NCurses.addstr('Hello world')

      Application.current.queue do
        FFI::NCurses.getch
      end
      Application.current.queue do
        FFI::NCurses.addstr('After an event... :)')
      end
    end

    def close!
      # TODO close any other threads
    end
  end
end
