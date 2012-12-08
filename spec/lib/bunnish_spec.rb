require "spec_helper"


describe Bunnish do
  describe "#parse_opts(argv)" do
    context "when argv = []" do
      it "should return defalut hash" do
        result = Bunnish.parse_opts([])
        result[:host].should == "localhost"
        result[:port].should == 5672
        result[:user].should == "guest"
        result[:password].should == "guest"
        result[:durable].should == false
        result[:ack].should == true
        result[:exchange_name].should == nil
        result[:unit_size].should == nil
        result[:raise_exception_flag].should == false
        result[:delimiter].should == nil
        result[:log_label].should == nil
        result[:log_dir].should == nil
        result[:log_path].should == nil
        result[:consumer_tag].should == nil
        result[:timeout].should == 1
        result[:exclusive].should == false
        result[:message_max].should == nil
        result[:current_all_flag].should == false
        result[:min_size].should == nil
        result[:empty_list_max].should == nil
        result[:warn_size].should == nil
        result[:error_size].should == nil
      end
    end

    argv = ("-h mq-server -p 15672 -u user -P password --durable t" \
      + " --ack f --exchange-name exchange --unit-size 10" \
      + " --raise-exception --delimiter delim" \
      + " --log-label log-label --log-dir log-dir --log-file log-file" \
      + " --consumer-tag ctag --timeout 11 --exclusive t --message-max 12" \
      + " --current-all --min-size 13 --empty-list-max 14" \
      + " --warn 15 --error 16").split(/ /)

    context "when argv = #{argv.inspect}" do
      it 'should return valid hash' do
        result = Bunnish.parse_opts(argv)
        result[:host].should == "mq-server"
        result[:port].should == 15672
        result[:user].should == "user"
        result[:password].should == "password"
        result[:durable].should == true
        result[:ack].should == false
        result[:exchange_name].should == "exchange"
        result[:unit_size].should == 10
        result[:raise_exception_flag].should == true
        result[:delimiter].should == "delim"
        result[:log_label].should == "[log-label]"
        result[:log_dir].should == "log-dir"
        result[:log_path].should == "log-file"
        result[:consumer_tag].should == "ctag"
        result[:timeout].should == 11
        result[:exclusive].should == true
        result[:message_max].should == "12"
        result[:current_all_flag].should == true
        result[:min_size].should == 13
        result[:empty_list_max].should == 14
        result[:warn_size].should == 15
        result[:error_size].should == 16
      end
    end
  end
end
