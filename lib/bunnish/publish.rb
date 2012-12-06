module Bunnish
  module Publish
    def self.output_log(streams, message)
      streams.each do |stream|
        if stream then
          stream.puts message
          stream.flush
        end
      end
    end
    
    def self.output_publish_log(streams, queue, count, log_label)
      message_count = '?'
      consumer_count = '?'
      begin
        message_count = queue.status[:message_count]
        consumer_count = queue.status[:consumer_count]
      rescue Exception=>e
      end
    
      self.output_log streams, Time.now.strftime("[%Y-%m-%d %H:%M:%S](INFO)#{log_label} published #{count} messages into #{queue.name}(#{message_count} messages, #{consumer_count} consumers)")
    end
    
    def self.run(argv, input_stream=$stdin, output_stream=$stdout, error_stream=$stderr)
      input_stream ||= $stdin
      output_stream ||= $stdout
      error_stream ||= $stderr
      
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
      
      
      queue_name_list = argv.shift.split(/[, \r\n]/)
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
          error_stream.puts Time.now.strftime("[%Y-%m-%d %H:%M:%S](INFO)#{log_label} output log into #{log_path}")
        end
      end
       
      fanout_flag = (exchange_name != '' && 1 < queue_name_list.size)
      
      bunny = nil
      direct_exchange = nil
      
      publish_flag = false
      
      begin
        direct_exchange_list = nil
        
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
              error_stream.puts Time.now.strftime("[%Y-%m-%d %H:%M:%S]") + "(INFO)#{log_label} create fanout exchange '#{exchange_name}'"
              fanout_exchange = bunny.exchange(exchange_name, :type=>:fanout, :persistent=>durable)
              queue_name_list.each do |queue_name|
              # create/get queue
                error_stream.puts Time.now.strftime("[%Y-%m-%d %H:%M:%S]") + "(INFO)#{log_label} create queue '#{queue_name}'"
                queue = bunny.queue(queue_name, :durable=>durable)
                error_stream.puts Time.now.strftime("[%Y-%m-%d %H:%M:%S]") + "(INFO)#{log_label} bind queue '#{queue_name}' to fanout exchange '#{exchange_name}'"
                queue.bind(fanout_exchange)
                self.output_log [error_stream, log_streams[queue_name]], Time.now.strftime("[%Y-%m-%d %H:%M:%S](INFO)#{log_label} publish to #{queue_name}(#{queue.status[:message_count]} messages, #{queue.status[:consumer_count]} consumers)")
              end
            else
              direct_exchange_list = queue_name_list.map { |queue_name|
      
                error_stream.puts Time.now.strftime("[%Y-%m-%d %H:%M:%S]") + "(INFO)#{log_label} create direct exchange '#{queue_name}'"
                direct_exchange = bunny.exchange(queue_name, :type=>:direct)
      
                error_stream.puts Time.now.strftime("[%Y-%m-%d %H:%M:%S]") + "(INFO)#{log_label} create queue '#{queue_name}'"
                queue = bunny.queue(queue_name, :durable=>durable)
      
                error_stream.puts Time.now.strftime("[%Y-%m-%d %H:%M:%S]") + "(INFO)#{log_label} bind queue '#{queue_name}' to direct exchange '#{queue_name}'"
                queue.bind(direct_exchange)
                self.output_log [error_stream, log_streams[queue_name]], Time.now.strftime("[%Y-%m-%d %H:%M:%S](INFO)#{log_label} publish to #{queue_name}(#{queue.status[:message_count]} messages, #{queue.status[:consumer_count]} consumers)")
      
                direct_exchange
              }
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
        
          if fanout_flag then
            fanout_exchange.publish(message)
          else
            direct_exchange_list.each do |direct_exchange|
              direct_exchange.publish(message)
            end
          end
          count += 1
          
          if unit_size <= count then
            publish_flag = true
            queue_name_list.each do |queue_name|
              queue = bunny.queue(queue_name, :durable=>durable)
              log_stream = log_streams[queue_name]
              self.output_publish_log [error_stream, log_stream], queue, count, log_label
            end
            count = 0
          end
        end
      
        publish_flag = true if 0 < count
        
        queue_name_list.each do |queue_name|
          log_stream = log_streams[queue_name]
          if bunny then
            queue = bunny.queue(queue_name, :durable=>durable)
            self.output_publish_log [error_stream, log_stream], queue, count, log_label if 0 < count || !publish_flag
          else
            self.output_log [error_stream, log_stream], Time.now.strftime("[%Y-%m-%d %H:%M:%S](INFO)#{log_label} no input for #{queue_name}")
          end
        end
        
        bunny.stop if bunny
      
      rescue Exception=>e
        if raise_exception_flag then
          bunny.stop if bunny
          raise e if raise_exception_flag
        else
          message = Time.now.strftime("[%Y-%m-%d %H:%M:%S](EXCEPTION)#{log_label} #{e.message}(#{e.class.name}): #{e.backtrace.map{|s| "  #{s}"}.join("\n")}")
            self.output_log(([error_stream] + log_streams.values), message)
        end
      end
      
      log_streams.values.each do |log_stream|
        log_stream.close
      end
    end

  end
end