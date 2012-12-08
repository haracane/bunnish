module Bunnish::Command
  module Subscribe
    def self.output_log(streams, message)
      streams.each do |stream|
        if stream then
          stream.puts message
          stream.flush
        end
      end
    end
    
    def self.output_subscribe_log(streams, queue, count, log_label)
      message_count = '?'
      consumer_count = '?'
      begin
        message_count = queue.status[:message_count]
        consumer_count = queue.status[:consumer_count]
      rescue Exception=>e
      end
    
      self.output_log streams, Time.now.strftime("[%Y-%m-%d %H:%M:%S](INFO)#{log_label} subscribed #{count} messages from #{queue.name}(#{message_count} messages, #{consumer_count} consumers)")
    end
    
    def self.run(argv, input_stream=$stdin, output_stream=$stdout, error_stream=$stderr)
      params = Bunnish.parse_opts(argv)
      
      host = params[:host]
      port = params[:port]
      user = params[:user]
      password = params[:password]
      durable = params[:durable]
      unit_size = params[:unit_size] || 10000
      raise_exception_flag = params[:raise_exception_flag]
      ack = params[:ack]
      consumer_tag = params[:consumer_tag]
      exclusive = params[:exclusive]
      message_max = params[:message_max]
      timeout = params[:timeout]
      current_all_flag = params[:current_all_flag]
      min_size = params[:min_size]
      
      log_label = params[:log_label]
      log_dir = params[:log_dir]
      log_path = params[:log_path]
      
      queue_name = argv.shift
      
      log_stream = nil
      
      log_path = "#{log_dir}/#{queue_name.gsub(/[\/]/, "_")}.log" if log_dir
      
      if log_path
        log_stream = open(log_path, "a")
        error_stream.puts Time.now.strftime("[%Y-%m-%d %H:%M:%S](INFO)#{log_label} output log into #{log_path}")
      end
      
      exchange_name = queue_name
      
      bunny = Bunny.new(:logging => false, :spec => '09', :host=>host, :port=>port, :user=>user, :pass=>password)
      
      
      # start a communication session with the amqp server
      bunny.start
      
      # create/get queue
      queue = bunny.queue(queue_name, :durable=>durable)
      
      remain_count = queue.status[:message_count]
      consumer_count = queue.status[:consumer_count]
      
      message_max = 'current-size' if current_all_flag
      
      if message_max == 'current-size' then
        message_max = remain_count
      elsif min_size
        message_max = [remain_count - min_size, 0].max
      else
        message_max = message_max.to_i if message_max
      end
      
      if message_max 
        self.output_log [error_stream, log_stream],  Time.now.strftime("[%Y-%m-%d %H:%M:%S](INFO)#{log_label} subscribe #{message_max} messages from #{queue_name}(#{remain_count} messages, #{consumer_count} consumers)")
      
        if message_max <= 0
          self.output_log [error_stream, log_stream],  Time.now.strftime("[%Y-%m-%d %H:%M:%S](INFO)#{log_label} finished")
          bunny.stop
          return 0
        end
      else
        self.output_log [error_stream, log_stream],  Time.now.strftime("[%Y-%m-%d %H:%M:%S](INFO)#{log_label} subscribe from #{queue_name}(#{remain_count} messages, #{consumer_count} consumers)")
      end
      
      if !exchange_name.nil? && exchange_name != '' then
        exchange = bunny.exchange(exchange_name)
        queue.bind(exchange)
      end
      
      total_count = 0
      count = 0
      
      subscribe_flag = false
      
      if remain_count == 0 then
        self.output_log [error_stream, log_stream], Time.now.strftime("[%Y-%m-%d %H:%M:%S](INFO)#{log_label} no messages in #{queue_name}(#{remain_count} messages, #{consumer_count} consumers)")
      else
        # subscribe to queue
        begin
          queue.subscribe(:ack=>ack, \
            :consumer_tag=>consumer_tag, \
            :exclusive=>exclusive, \
            :message_max=>message_max, \
            :timeout=>timeout) do |msg|
            if msg && msg[:payload] then
              output_stream.puts msg[:payload]
              count += 1
              total_count += 1
              if unit_size <= count then
                subscribe_flag = true
                self.output_log [error_stream, log_stream], Time.now.strftime("[%Y-%m-%d %H:%M:%S](INFO)#{log_label} subscribed #{count} messages from #{queue_name}")
                count = 0
                break if min_size && remain_count <= total_count + min_size
              end
            end
          end
        rescue Exception=>e
          if raise_exception_flag then
            bunny.stop if bunny
            raise e if raise_exception_flag
          else
            self.output_log [error_stream, log_stream],  Time.now.strftime("[%Y-%m-%d %H:%M:%S](EXCEPTION)#{log_label} #{e.message}(#{e.class.name}): #{e.backtrace.map{|s| "  #{s}"}.join("\n")}")
          end
        end
      end
      
      subscribe_flag = true if 0 < count
      
      self.output_subscribe_log [error_stream, log_stream], queue, count, log_label # if 0 < count || subscribe_flag
      
      if log_stream then
        log_stream.close
      end
      
      # Close client
      bunny.stop
      
      return 0
    end
  end
end