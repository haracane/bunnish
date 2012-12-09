module Bunnish::Core
  module Common
    def self.output_log(streams, log_level, message)
      case log_level
      when "INFO"
        Bunnish.logger.info(message)
      when "EXCEPTION"
        Bunnish.logger.warn(message)
      end
      message =  Time.now.strftime("[%Y-%m-%d %H:%M:%S](#{log_level})#{message}")
      streams.each do |stream|
        if stream then
          stream.puts message
          stream.flush
        end
      end
    end
  end
end
