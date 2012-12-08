module Bunnish::Command
  module Help
    def self.run(argv, input_stream=$stdin, output_stream=$stdout, error_stream=$stderr)
      output_stream.puts <<EOF
usage: bunnish COMMAND OPTIONS
EOF

      return 0
    end
  end
end