module Bunnish::Command
  module Publish
    def self.run(argv, input_stream=$stdin, output_stream=$stdout)
      
      params = Bunnish.parse_opts(argv)
      
      host = params[:host]
      port = params[:port]
      user = params[:user]
      password = params[:password]
      durable = params[:durable]
      exchange_name = params[:exchange_name]
      unit_size = params[:unit_size] || 100000
      raise_exception_flag = params[:raise_exception_flag]
      delimiter = params[:delimiter]
      
      log_label = params[:log_label]
      log_dir = params[:log_dir]
      log_path = params[:log_path]
      
      
      queue_name_list = argv.shift

      if queue_name_list.nil?
        Bunnish.logger.error("queue-name is not set")
        return 1
      end
      
      queue_name_list = queue_name_list.split(/[, \r\n]/)
      queue_name_list.delete('')
      
      if delimiter
        delimiter_crlf = "#{delimiter}\r\n"
        delimiter_lf = "#{delimiter}\n"
      end
      
      log_streams = {}
      
      queue_name_list.each do |queue_name|
        log_path = "#{log_dir}/#{queue_name.gsub(/[\/]/, "_")}.log" if log_dir
        if log_path then
          log_stream = open(log_path, "a")
          log_streams[queue_name] = log_stream
          Bunnish.logger.info "#{log_label} output log into #{log_path}"
        end
      end
       
      fanout_flag = (exchange_name && exchange_name != '' && 1 < queue_name_list.size)
      
      bunny = nil
      
      publish_flag = false
      
      exchange_list = []
      
      begin
        # publish message to exchange
        count = 0
        
        lines = []
        
        while line = input_stream.gets do
          if bunny == nil then
            bunny = Bunny.new(:logging => false, :spec => '09', :host=>host, :port=>port, :user=>user, :pass=>password)
            # start a communication session with the amqp server
            bunny.start
            # create/get exchange  
            if fanout_flag then
              fanout_exchange = Bunnish::Core::Publish.create_fanout_exchange(bunny, queue_name_list, log_streams, params)
              exchange_list.push fanout_exchange
            else
              direct_exchange_list = queue_name_list.map {|queue_name|
                Bunnish::Core::Publish.create_direct_exchange(bunny, queue_name, log_streams, params)
              }
              exchange_list = direct_exchange_list
            end
            
            queue_name_list.each do |queue_name|
              queue = bunny.queue(queue_name, :durable=>durable)
              message = "#{log_label} publish to #{queue_name}(#{queue.status[:message_count]} messages, #{queue.status[:consumer_count]} consumers)"
              Bunnish::Core::Common.output_log [log_streams[queue_name]], "INFO", message
            end
          end
        
          if delimiter
            lines.push line
            next if /^#{Regexp.escape(delimiter)}\r?\n$/ !~ line
            message = lines.join
            lines.clear
          else
            message = line
          end
        
          exchange_list.each do |exchange|
            exchange.publish(message)
          end
            
          count += 1
          
          if unit_size <= count then
            publish_flag = true
            queue_name_list.each do |queue_name|
              queue = bunny.queue(queue_name, :durable=>durable)
              log_stream = log_streams[queue_name]
              Bunnish::Core::Publish.output_publish_log [log_stream], queue, count, log_label
            end
            count = 0
          end
        end
      
        publish_flag = true if 0 < count
        
        queue_name_list.each do |queue_name|
          log_stream = log_streams[queue_name]
          if bunny then
            queue = bunny.queue(queue_name, :durable=>durable)
            Bunnish::Core::Publish.output_publish_log [log_stream], queue, count, log_label if 0 < count || !publish_flag
          else
            Bunnish::Core::Common.output_log [log_stream], "INFO", "#{log_label} no input for #{queue_name}"
          end
        end
        
        bunny.stop if bunny
      
      rescue Exception=>e
        if raise_exception_flag then
          bunny.stop if bunny
          raise e if raise_exception_flag
        else
          message = "#{log_label} #{e.message}(#{e.class.name}): #{e.backtrace.map{|s| "  #{s}"}.join("\n")}"
          Bunnish::Core::Common.output_log(log_streams.values, "EXCEPTION", message)
        end
      end
      
      log_streams.values.each do |log_stream|
        log_stream.close
      end
      
      return 0
    end

  end
end