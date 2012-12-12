module Bunnish::Core
  module Common
    def self.parse_opts(argv)
      host = 'localhost'
      port = 5672
      user = 'guest'
      password = 'guest'
      durable = false
      ack = true
      raise_exception_flag = false
      
      exchange_name = nil
      delimiter = nil
  
      consumer_tag = nil
      exclusive = false
      message_max = nil
      timeout = 1
      unit_size = nil
      min_size = nil
      current_all_flag = false
  
      warn_size = nil
      error_size = nil
      
      log_label = nil
      log_dir = nil
      log_path = nil
      
      verbose_flag = false
      
      next_argv = []
      
      while 0 < argv.size do
        val = argv.shift
        case val
        when '-h'
          host = argv.shift
        when '-p'
          port = argv.shift.to_i
        when '-u'
          user = argv.shift
        when '-P'
          password = argv.shift
        when '--ack'
          ack = (argv.shift == 't')
        when '--delimiter'
          delimiter = argv.shift
        when '--durable'
          durable = (argv.shift == 't')
        when '--exchange-name'
          exchange_name = argv.shift
        when '--unit-size'
          unit_size = argv.shift.to_i
        when '--log-label'
          log_label = argv.shift
          log_label = "[#{log_label}]"
        when '--log-dir'
          log_dir = argv.shift
        when '--log-file'
          log_path = argv.shift
        when '--raise-exception'
          raise_exception_flag = true
        when '--consumer-tag'
          consumer_tag = argv.shift
        when '--timeout'
          timeout = argv.shift.to_i
        when '--exclusive'
          exclusive = (argv.shift == 't')
        when '--message-max'
          message_max = argv.shift
        when '--current-all'
          current_all_flag = true
        when '--min-size'
          min_size = argv.shift.to_i
        when '--empty-list-max'
          empty_list_max = argv.shift.to_i
        when '--warn'
          warn_size = argv.shift.to_i
        when '--error'
          error_size = argv.shift.to_i
        when '--verbose'
          verbose_flag = true
        else 
          next_argv.push val
        end
      end
      argv.push(*next_argv)
      
      if verbose_flag then
        Bunnish.logger.level = Logger::INFO
      else
        Bunnish.logger.level = Logger::WARN
      end
      
      return {
        :host=>host,
        :port=>port,
        :user=>user,
        :password=>password,
        :durable=>durable,
        :ack=>ack,
        :exchange_name=>exchange_name,
        :unit_size=>unit_size,
        :raise_exception_flag=>raise_exception_flag,
        :delimiter=>delimiter,
        :log_label=>log_label,
        :log_dir=>log_dir,
        :log_path=>log_path,
        :consumer_tag=>consumer_tag,
        :timeout=>timeout,
        :exclusive=>exclusive,
        :message_max=>message_max,
        :current_all_flag=>current_all_flag,
        :min_size=>min_size,
        :empty_list_max=>empty_list_max,
        :warn_size=>warn_size,
        :error_size=>error_size,
        :verbose_flag=>verbose_flag
      }
      
    end

    def self.output_log(streams, log_level, message)
      case log_level
      when "INFO"
        Bunnish.logger.info(message)
      when "EXCEPTION"
        Bunnish.logger.warn(message)
      end
      message =  Time.now.strftime("[%Y-%m-%d %H:%M:%S](#{log_level})#{message}")
      streams.each do |stream|
        if stream then
          stream.puts message
          stream.flush
        end
      end
    end
  end
end
