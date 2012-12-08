module Bunnish::Command
  module Delete
    def self.fetch_queue_name(queue_name_list, input_stream)
      return queue_name_list.shift if queue_name_list
      line = input_stream.gets
      return line.chomp if line
      return nil
    end
        
    def self.run(argv, input_stream=$stdin, output_stream=$stdout, error_stream=$stderr)
    
      params = Bunnish.parse_opts(argv)
      
      host = params[:host]
      port = params[:port]
      user = params[:user]
      password = params[:password]
      durable = params[:durable]

      queue_name_list = argv.shift
      
      queue_name_list = queue_name_list.split(/[, \r\n]+/) if queue_name_list
      
      bunny = Bunny.new(:logging => false, :spec => '09', :host=>host, :port=>port, :user=>user, :pass=>password)
      
      # start a communication session with the amqp server
      bunny.start
      
      exit_code = 0
      
      while queue_name = self.fetch_queue_name(queue_name_list, input_stream)
        # create/get queue
        # queue = bunny.queues[queue_name]
        queue = bunny.queue(queue_name, :durable=>durable)

        if queue.nil? then
          error_stream.puts Time.now.strftime("[%Y-%m-%d %H:%M:%S](INFO) #{queue_name} does not exist")
          next
        end

        result = queue.delete

        if result == :delete_ok then
          error_stream.puts Time.now.strftime("[%Y-%m-%d %H:%M:%S](INFO) deleted #{queue_name}")
        else
          error_stream.puts Time.now.strftime("[%Y-%m-%d %H:%M:%S](ERROR) failed to #{queue_name}")
          exit_code = 1
        end
      end
      
      # Close client
      bunny.stop
      
      return exit_code
    end
  end
end