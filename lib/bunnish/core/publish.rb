module Bunnish::Core
  module Publish
    def self.output_publish_log(streams, queue, count, log_label)
      message_count = '?'
      consumer_count = '?'
      begin
        message_count = queue.status[:message_count]
        consumer_count = queue.status[:consumer_count]
      rescue Exception=>e
      end
      
      message = "#{log_label} published #{count} messages into #{queue.name}(#{message_count} messages, #{consumer_count} consumers)"
      Bunnish::Core::Common.output_log(streams, "INFO", message)
    end
    
    def self.create_fanout_exchange(bunny, queue_name_list, log_streams={}, options={})
      durable = options[:durable]
      log_label = options[:log_label]
      exchange_name = options[:exchange_name]
      
      Bunnish.logger.info "#{log_label} create fanout exchange '#{exchange_name}'"
      fanout_exchange = bunny.exchange(exchange_name, :type=>:fanout, :persistent=>durable)
      
      queue_name_list.each do |queue_name|
      # create/get queue
        Bunnish.logger.info "#{log_label} create queue '#{queue_name}'"
        queue = bunny.queue(queue_name, :durable=>durable)
        Bunnish.logger.info "#{log_label} bind queue '#{queue_name}' to fanout exchange '#{exchange_name}'"
        queue.bind(fanout_exchange)
      end
      return fanout_exchange
    end
    
    def self.create_direct_exchange(bunny, queue_name, log_streams={}, options={})
      durable = options[:durable]
      log_label = options[:log_label]

      Bunnish.logger.info "#{log_label} create direct exchange '#{queue_name}'"
      direct_exchange = bunny.exchange(queue_name, :type=>:direct)

      Bunnish.logger.info "#{log_label} create queue '#{queue_name}'"
      queue = bunny.queue(queue_name, :durable=>durable)

      Bunnish.logger.info "#{log_label} bind queue '#{queue_name}' to direct exchange '#{queue_name}'"
      queue.bind(direct_exchange)

      return direct_exchange
    end
  end
end
