require 'open3'

module Email
   CONFIG_FILE = './config/clefable_ssmtp.conf'
   SSMTP_COMMAND = '/usr/sbin/ssmtp'

   def sendMail(subject, body, address)
      stdin, stdout, stderr, wait_thr = Open3.popen3("#{SSMTP_COMMAND} -C #{CONFIG_FILE} #{address}")

      stdin.puts("Subject: #{subject}")
      stdin.puts("To: #{address}")
      stdin.puts("\n" + body)

      stdin.close
      stdout.close
      stderr.close
      exit_status = wait_thr.value 

      return exit_status
   end
end
