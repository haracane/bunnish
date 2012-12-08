$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require "rspec"
require "bunnish"
require "tempfile"

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
  
end

module Bunnish
  BUNNISH_HOME = File.expand_path(File.dirname(__FILE__) + "/..")
  BIN_DIR = "#{BUNNISH_HOME}/bin"
  LIB_DIR = "#{BUNNISH_HOME}/lib"
  RUBY_CMD = "/usr/bin/env ruby -I #{LIB_DIR}"
  REDIRECT = {:stderr=>"/dev/null"}
end
