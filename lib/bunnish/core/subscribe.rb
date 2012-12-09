module Bunnish::Core
  module Subscribe
    def self.output_subscribe_log(streams, queue, count, log_label)
      message_count = '?'
      consumer_count = '?'
      begin
        message_count = queue.status[:message_count]
        consumer_count = queue.status[:consumer_count]
      rescue Exception=>e
      end
    
      message = "#{log_label} subscribed #{count} messages from #{queue.name}(#{message_count} messages, #{consumer_count} consumers)"
      Bunnish::Core::Common.output_log(streams, "INFO", message)
    end
  end
end