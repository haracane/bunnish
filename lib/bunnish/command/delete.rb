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
      
      log_label = params[:log_label]

      queue_name_list = argv.shift

      if queue_name_list.nil?
        Bunnish.logger.error("queue-name is not set")
        return 1
      end
      
      queue_name_list = queue_name_list.split(/[, \r\n]/)
      queue_name_list.delete('')
      
      bunny = Bunny.new(:logging => false, :spec => '09', :host=>host, :port=>port, :user=>user, :pass=>password)
      
      # start a communication session with the amqp server
      bunny.start
      
      exit_code = 0
      
      while queue_name = self.fetch_queue_name(queue_name_list, input_stream)
        # create/get queue
        # queue = bunny.queues[queue_name]
        queue = bunny.queue(queue_name, :durable=>durable)

        if queue.nil? then
          Bunnish.logger.info "#{log_label} #{queue_name} does not exist"
          next
        end

        result = queue.delete

        if result == :delete_ok then
          Bunnish.logger.info "#{log_label} deleted #{queue_name}"
        else
          Bunnish.logger.warn "#{log_label} failed to delete #{queue_name}"
          exit_code = 1
        end
      end
      
      # Close client
      bunny.stop
      
      return exit_code
    end
  end
end