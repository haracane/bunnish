require "spec_helper"

describe "bin/bunnish" do
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
  describe "count" do
    it "should output valid queue count" do
      result = `#{Bunnish::RUBY_CMD} #{Bunnish::BIN_DIR}/bunnish count bunnish-test-queue #{@stderr_dst}`
      result.chomp!
      result.should == "3"
    end
  end
  describe "delete" do
    it "should delete queue" do
      `#{Bunnish::RUBY_CMD} #{Bunnish::BIN_DIR}/bunnish delete bunnish-test-queue #{@stderr_dst}`
      result = `#{Bunnish::RUBY_CMD} #{Bunnish::BIN_DIR}/bunnish count bunnish-test-queue 2> /dev/null`
      result = result.chomp!
      result.should == "0"
    end
  end
  describe "help" do
    it "should delete queue" do
      result = `#{Bunnish::RUBY_CMD} #{Bunnish::BIN_DIR}/bunnish help bunnish-test-queue #{@stderr_dst}`
      result.split().size.should > 0
      $?.should == 0
    end
  end
  describe "publish" do
    context "when exchange-name is not set" do
      it "should publish valid messages with direct exchange" do
        `cat #{@input_file.path} | #{Bunnish::RUBY_CMD} #{Bunnish::BIN_DIR}/bunnish publish bunnish-test-queue,bunnish-test-queue-2 #{@stderr_dst}`
        result = `#{Bunnish::RUBY_CMD} #{Bunnish::BIN_DIR}/bunnish subscribe bunnish-test-queue 2> /dev/null`
        result = result.split()
        # result.each do |line| STDERR.puts line end
        result.shift.should == "foo"
        result.shift.should == "bar"
        result.shift.should == "baz"
        result.shift.should == "foo"
        result.shift.should == "bar"
        result.shift.should == "baz"
        result.size.should == 0

        result = `#{Bunnish::RUBY_CMD} #{Bunnish::BIN_DIR}/bunnish subscribe bunnish-test-queue-2 2> /dev/null`
        result = result.split()
        result.shift.should == "foo"
        result.shift.should == "bar"
        result.shift.should == "baz"
        result.size.should == 0
      end
    end
    
    context "when exchange-name is set" do
      it "should publish valid messages with fanout exchange" do
        `cat #{@input_file.path} | #{Bunnish::RUBY_CMD} #{Bunnish::BIN_DIR}/bunnish publish --exchange-name bunnish-test-exchange bunnish-test-queue,bunnish-test-queue-2 #{@stderr_dst}`
        result = `#{Bunnish::RUBY_CMD} #{Bunnish::BIN_DIR}/bunnish subscribe bunnish-test-queue 2> /dev/null`
        result = result.split()
        # result.each do |line| STDERR.puts line end
        result.shift.should == "foo"
        result.shift.should == "bar"
        result.shift.should == "baz"
        result.shift.should == "foo"
        result.shift.should == "bar"
        result.shift.should == "baz"
        result.size.should == 0

        result = `#{Bunnish::RUBY_CMD} #{Bunnish::BIN_DIR}/bunnish subscribe bunnish-test-queue-2 2> /dev/null`
        result = result.split()
        result.shift.should == "foo"
        result.shift.should == "bar"
        result.shift.should == "baz"
        result.size.should == 0
      end
    end
  end
  describe "status" do
    it "should print valid status of message queue" do
      result = `#{Bunnish::RUBY_CMD} #{Bunnish::BIN_DIR}/bunnish status bunnish-test-queue #{@stderr_dst}`
      result = result.split(/\n/)
      # STDERR.puts result.inspect
      result.include?("bunnish-test-queue : 3 messages, 0 consumers").should be_true
    end
  end
  describe "subscribe" do
    it "should subscribe valid messages" do
      result = `#{Bunnish::RUBY_CMD} #{Bunnish::BIN_DIR}/bunnish subscribe bunnish-test-queue #{@stderr_dst}`
      result = result.split()
      # result.each do |line| STDERR.puts line end
      result.shift.should == "foo"
      result.shift.should == "bar"
      result.shift.should == "baz"
    end
  end
end
