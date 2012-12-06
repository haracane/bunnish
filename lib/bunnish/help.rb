module Bunnish
  module Help
    def self.run(argv, input_stream=$stdin, output_stream=$stdout, error_stream=$stderr)
      output_stream.puts <<EOF
usage: bunnish COMMAND OPTIONS
EOF
    end
  end
end