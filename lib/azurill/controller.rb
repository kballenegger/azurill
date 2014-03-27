
module Azurill
  
  class Controller

    def initialize
      # :)

      Application.current.queue do
        FFI::NCurses.addstr("Hello world\n")
      end

      Thread.new do
        sleep(3)
        Application.current.next do
          Application.exit!
        end
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

    def close!
      # TODO close any other threads
    end
  end
end
