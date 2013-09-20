require 'spec_helper'

describe DScript::Runner do
  let(:settings) do
    { driver: "ruby", url: "redis://localhost:6379", db: 0, timeout: 5 }
  end
  let(:runner) { DScript::Runner.new("test", settings) }
  
  before(:each) do
    Redis.any_instance.should_receive(:incr).and_return(1)
  end

  describe "#name" do
    it "returns the channel name for the runner" do
      DScript::Runner.new("test", settings).name.should == "test-runner-1"
    end
  end

  describe "#run" do
    let(:output) { double() }

    before(:each) do
      File.should_receive(:open).with('/home/bzanchet/test-runner-1.txt', 'w').and_return(output)
      runner.should_receive(:load_script)
      runner.should_receive(:start)
      output.should_receive(:puts)
      output.should_receive(:close)
      runner.set_script("script" => "test.rb", "output_dir" => "/home/bzanchet/")
      runner.run('test-master')
    end

    it "initializes the slave" do
      runner.master_ch.should == 'test-master'
    end
  end
end
