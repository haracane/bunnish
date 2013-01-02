module BunnyExtensions
  module Qrack
    module Client
      module Requests
        def queue_message_counts(queue_names, queue_options={})
          ret = {}
          queue_names.each do |queue_name|
            queue = self.queue(queue_name, queue_options)
            ret[queue_name] = queue.status[:message_count]
          end
          return ret
        end
      end
    end
  end
end

module Qrack
  class Client
    include BunnyExtensions::Qrack::Client::Requests
  end
end
