require "spec_helper"

describe BunnyExtensions do
  before :all do
    @stderr_dst = Bunnish::REDIRECT[:stderr]
    @input_file = Tempfile.new("bunnish")
    @input_file.puts "foo"
    @input_file.puts "bar"
    @input_file.puts "baz"
    @input_file.close
    `#{Bunnish::RUBY_CMD} #{Bunnish::BIN_DIR}/bunnish delete bunnish-test-queue 2> /dev/null`
  end
  after :all do
    @input_file.unlink
  end
  before :each do
    `cat #{@input_file.path} | #{Bunnish::RUBY_CMD} #{Bunnish::BIN_DIR}/bunnish publish bunnish-test-queue 2> /dev/null`
  end
  after :each do
    `#{Bunnish::RUBY_CMD} #{Bunnish::BIN_DIR}/bunnish delete bunnish-test-queue,bunnish-test-queue-2 2> /dev/null`
  end
  
  describe "Bunny#queue_message_counts" do
    it "should return queue message count hash" do
      bunny = Bunny.new(:logging => false, :spec => "09", :host=>"localhost", :port=>5672, :user=>"guest", :pass=>"guest")
      bunny.start
      result = bunny.queue_message_counts(["bunnish-test-queue"], :durable=>false)
      result["bunnish-test-queue"].should == 3
      bunny.stop
    end
  end
  
end
