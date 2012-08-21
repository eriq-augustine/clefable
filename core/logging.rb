# Everything required for logging.

INFO = 0
DEBUG = 1
WARN = 2
ERROR = 3
FATAL = 4

LOG_BASE = 'clefable'
LOG_EXT = 'log'

def log(level, message)
   callingFrame = caller(0)[1]
   if (callingFrame && callingFrame.length > 0)
      message = "(#{callingFrame}) #{message}"
   end

   case level
   when INFO
      puts "[INFO] #{message}"
      writeLog('', message)
   when DEBUG
      if ($DEBUG)
         puts "[DEBUG] #{message}"
         writeLog('_debug', message)
      end
   when WARN
      puts "[WARN] #{message}"
      writeLog('_warn', message)
   when ERROR
      puts "[ERROR] #{message}"
      writeLog('_error', message)
   when FATAL
      logFatal(message)
   else
      #TODO Handle properly, maybe FATAL error
      puts "Inproper logging level: #{level}. Message: #{message}"
   end
end

def writeLog(logFileSuffix, message)
   file = File.open("#{LOG_DIR}/#{LOG_BASE}#{logFileSuffix}.#{LOG_EXT}", 'a')

   file.puts("\n***** #{Time.now()} ****")
   file.puts(message)
   file.puts('*' * 37)

   file.close()
end

def logFatal(message)
   fullMessage = message + "\n"

   stack = caller()
   puts "[FATAL] #{message}"
   stack.each{|frame|
      puts "#{frame}"
      message += "#{frame}\n"
   }
   writeLog('_fatal', message)
   exit(1)
end

def notreached(message = nil)
   logFatal("NOT REACHED -- #{message}")
end

def check(val)
   if (!val)
      logFatal("Check Failed")
   end
end
