module Bunnish::Command
  module Count
    def self.run(argv, input_stream=$stdin, output_stream=$stdout)
      
      params = Bunnish.parse_opts(argv)
      
      host = params[:host]
      port = params[:port]
      user = params[:user]
      password = params[:password]
      durable = params[:durable]
      
      queue_name = argv[0]
      
      bunny = Bunny.new(:logging => false, :spec => '09', :host=>host, :port=>port, :user=>user, :pass=>password)
      
      # start a communication session with the amqp server
      bunny.start
      
      # create/get queue
      queue = bunny.queue(queue_name, :durable=>durable)
      
      # remain_count = queue.status[:message_count]
        
      output_stream.puts queue.status[:message_count]
      
      # Close client
      bunny.stop
      
    end
  end
end