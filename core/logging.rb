# Everything required for logging.

INFO = 0
DEBUG = 1
WARN = 2
ERROR = 3
FATAL = 4

def log(level, message)
   case level
   when INFO
      puts "[INFO] #{message}"
   when DEBUG
      puts "[DEBUG] #{message}"
   when WARN
      puts "[WARN] #{message}"
   when ERROR
      puts "[ERROR] #{message}"
   when FATAL
      logFatal(message)
   else
      #TODO Handle properly, maybe FATAL error
      puts "Inproper logging level: #{level}. Message: #{message}"
   end
end

def logFatal(message)
   stack = caller()
   puts "[FATAL] #{message}"
   stack.each{|frame|
      puts "#{frame}"
   }
   exit(1)
end

def notreached(message = nil)
   logFatal("NOT REACHED -- #{message}")
end
