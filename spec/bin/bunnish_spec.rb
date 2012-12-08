require "spec_helper"

describe "bin/bunnish" do
  before :all do
    @stderr = Bunnish::REDIRECT[:stderr]
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
    `#{Bunnish::RUBY_CMD} #{Bunnish::BIN_DIR}/bunnish delete bunnish-test-queue 2> /dev/null`
  end
  describe "count" do
    it "should output valid queue count" do
      result = `#{Bunnish::RUBY_CMD} #{Bunnish::BIN_DIR}/bunnish count bunnish-test-queue 2> #{@stderr}`
      result.chomp!
      result.should == "3"
    end
  end
  describe "delete" do
    it "should delete queue" do
      `#{Bunnish::RUBY_CMD} #{Bunnish::BIN_DIR}/bunnish delete bunnish-test-queue 2> #{@stderr}`
      result = `#{Bunnish::RUBY_CMD} #{Bunnish::BIN_DIR}/bunnish count bunnish-test-queue 2> /dev/null`
      result = result.chomp!
      result.should == "0"
    end
  end
  describe "help" do
    it "should delete queue" do
      result = `#{Bunnish::RUBY_CMD} #{Bunnish::BIN_DIR}/bunnish help bunnish-test-queue 2> #{@stderr}`
      result.split().size.should > 0
      $?.should == 0
    end
  end
  describe "publish" do
    it "should publish valid messages" do
      `echo qux | #{Bunnish::RUBY_CMD} #{Bunnish::BIN_DIR}/bunnish publish bunnish-test-queue 2> #{@stderr}`
      result = `#{Bunnish::RUBY_CMD} #{Bunnish::BIN_DIR}/bunnish subscribe bunnish-test-queue 2> /dev/null`
      result = result.split()
      # result.each do |line| STDERR.puts line end
      result.shift.should == "foo"
      result.shift.should == "bar"
      result.shift.should == "baz"
      result.shift.should == "qux"
      result.size.should == 0
    end
  end
  describe "status" do
    it "should print valid status of message queue" do
      result = `#{Bunnish::RUBY_CMD} #{Bunnish::BIN_DIR}/bunnish status bunnish-test-queue 2> #{@stderr}`
      result = result.split(/\n/)
      # STDERR.puts result.inspect
      result.include?("bunnish-test-queue : 3 messages, 0 consumers").should be_true
    end
  end
  describe "subscribe" do
    it "should subscribe valid messages" do
      result = `#{Bunnish::RUBY_CMD} #{Bunnish::BIN_DIR}/bunnish subscribe bunnish-test-queue 2> #{@stderr}`
      result = result.split()
      # result.each do |line| STDERR.puts line end
      result.shift.should == "foo"
      result.shift.should == "bar"
      result.shift.should == "baz"
    end
  end
end
