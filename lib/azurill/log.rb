
module Azurill

  class Logger
    def self.log(m)
      @logfile ||= begin
                     f = File.open('Azurill.log', 'a')
                     f.sync = true
                     f.puts('***')
                     f
                   end
      
      @logfile.puts(m)
      @logfile.flush
    end
  end
end
