module Bunnish::Command
  module Help
    def self.run(argv, input_stream=$stdin, output_stream=$stdout)
      output_stream.puts <<-EOF
usage: bunnish COMMAND [-h HOST] [-p PORT] [-u USER] [-P PASSWORD]
            [--durable FLAG] [--ack FLAG] [--raise-exception]
            [--log-label LABEL] [--log-dir DIR] [--log-file FILE]
            <QUEUE_NAME[,...]>
  -h HOST      message queue server address. default is localhost. 
  -p PORT      port number. default is 5672.
  -u USER      user name. default is 'guest'.
  -P PASSWORD  password. default is 'guest'.
  --durable  FLAG   FLAG=t:disk queue; FLAG=f:memory queue(default).
  --ack      FLAG   FLAG=t:enable ack(default); FLAG=t:disable ack.
  --raise-exception raise exception.
  --log-label LABEL set log label.
  --log-dir  DIR    set log directory.
  --log-file FILE   set log file.
      EOF
      return 0
    end
  end
end
