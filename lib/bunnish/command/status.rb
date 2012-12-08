module Bunnish::Command
  module Status
    def self.run(argv, input_stream=$stdin, output_stream=$stdout, error_stream=$stderr)
      
      params = Bunnish.parse_opts(argv)
      
      host = params[:host]
      port = params[:port]
      user = params[:user]
      password = params[:password]
      durable = params[:durable]
      empty_list_max = params[:durable]
      
      warn_size = params[:warn_size] || 100000
      error_size = params[:error_size] || 500000
      
      warn_flag = false
      error_flag = false
      
      queue_name_list = argv.shift.split(/[, ]+/)
      
      begin
        bunny = Bunny.new(:logging => false, :spec => '09', :host=>host, :port=>port, :user=>user, :pass=>password)
      
        # start a communication session with the amqp server
        bunny.start
        
        empty_queue_list = []
        
        queue_name_list.each do |queue_name|
        
          if queue_name == '' then
            next
          end
          
          # create/get queue
          queue = bunny.queue(queue_name, :durable=>durable)
          
          message_count = queue.status[:message_count]
          
          empty_queue_list.push queue_name if message_count == 0
          
          if 0 < message_count then
            if error_size < message_count then
              output_stream.puts "(ERROR) #{queue_name} : #{queue.status[:message_count]} messages(> #{error_size}), #{queue.status[:consumer_count]} consumers"
              error_flag = true
            elsif warn_size < message_count then
              output_stream.puts "(WARNING) #{queue_name} : #{queue.status[:message_count]} messages(> #{warn_size}), #{queue.status[:consumer_count]} consumers"
              warn_flag = true
            else
              output_stream.puts "#{queue_name} : #{queue.status[:message_count]} messages, #{queue.status[:consumer_count]} consumers"
            end
          end
        end
        
        empty_count = empty_queue_list.size
        
        if empty_queue_list != [] then
          if empty_count == 1 then
            output_stream.puts "#{empty_count} queue is empty:"
          else
            output_stream.puts "#{empty_count} queues are empty:"
          end
          
          if empty_list_max then
            empty_queue_list = empty_queue_list[0..(empty_list_max-1)]
          end
          
          empty_queue_list.each do |queue_name|
            output_stream.puts "  #{queue_name}"
          end
          rest_count = empty_count - empty_queue_list.size
          output_stream.puts "  ..." if 0 < rest_count
        end
        # Close client
        bunny.stop
      
      rescue Exception=>e
        message = Time.now.strftime("[%Y-%m-%d %H:%M:%S](EXCEPTION)#{e.message}(#{e.class.name}): #{e.backtrace.map{|s| "  #{s}"}.join("\n")}")
        output_stream.puts message
        return 1
      end
      
      return 1 if error_flag
      return 2 if warn_flag
      return 0
    end
  end
end