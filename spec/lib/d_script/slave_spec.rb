require 'spec_helper'

describe DScript::Slave do
  let(:settings) do
    { driver: "ruby", url: "redis://localhost:6379", db: 0, timeout: 5 }
  end
  let(:slave) { slave = DScript::Slave.new("test", settings) }

  before(:each) do
    slave.runners = {}
  end

  describe "#name" do
    it "returns the channel name for the slave" do
      Redis.any_instance.should_receive(:incr).and_return(1)
      DScript::Slave.new("test", settings).name.should == "test-slave-1"
    end
  end

  describe "#done?" do
    it "returns true if num_runners < runners.length" do
      slave.runners = { test: 1, test_2: 2 }
      slave.num_runners = 1
      slave.should be_done
    end

    it "returns false if num_runners >= runners.length" do
      slave.runners = {}
      slave.num_runners = 1
      slave.should_not be_done
    end

    it "returns true if the master is done" do
      slave.should_receive(:stop)
      slave.runners = {}
      slave.master_done({"runner_ch" => "test"})
      slave.should be_done
    end
  end

  describe "#run" do
    before(:each) do
      slave.should_receive(:start)
      slave.run(1, 'test')
    end

    it "initializes the slave" do
      slave.runners.should == {}
      slave.num_runners.should == 1
      slave.env.should == "test"
    end
  end

  describe "#register" do
    it "sends a register event to master" do
      slave.should_receive(:d_emit).with("test-master", event: "register", name: slave.name)
      slave.register
    end
  end

  describe "#set_script" do
    it "sets the script" do
      slave.should_receive(:start_runners)
      slave.set_script("script" => "test.rb")
      slave.script.should == "test.rb"
    end
  end

  describe "#next_block" do
    it "sends the next block to the runner" do
      slave.should_receive(:d_emit).with("runner_name", "runner_ch" => "runner_name", :event => "next_block", :start => 1)
      slave.next_block("runner_ch" => "runner_name", :event => "next_block", :start => 1)
    end
  end

  describe "#master_done" do
    before(:each) do
      slave.should_receive(:unregister_runner).with("runner_name")
    end

    it "sets done to true" do
      slave.master_done("runner_ch" => "runner_name")
      slave.should be_done
    end

    it "sends the done event to the runner channel" do
      slave.should_receive(:d_emit).with("runner_name", event: "done")
      slave.master_done("runner_ch" => "runner_name")
    end
  end

  describe "#ready" do
    it "tells the master that the runner is ready" do
      slave.should_receive(:d_emit).with("test-master", event: "ready", name: slave.name, runner_ch: "runner_name")
      slave.ready("runner_name")
    end
  end

  describe "#runner_ready" do
    describe "when done? is true" do
      it "sends done to the runner channel" do
        slave.should_receive(:done?).and_return(true)
        slave.should_receive(:unregister_runner).with("runner_name")
        slave.should_receive(:d_emit).with("runner_name", event: "done")
        slave.runner_ready("name" => "runner_name")
      end
    end

    describe "when done? is false" do
      it "tells master it is ready" do
        slave.should_receive(:done?).and_return(false)
        slave.should_receive(:d_emit).with("test-master", event: "ready", name: slave.name, runner_ch: "runner_name")
        slave.runner_ready("name" => "runner_name")
      end
    end
  end

  describe "#register_runner" do
    it "sends the script to the runner" do
      slave.should_receive(:d_emit).with("runner_name", event: "registered", script: "test.rb")
      slave.script = "test.rb"
      slave.register_runner("name" => "runner_name")
    end
  end

  describe "#unregister_runner" do
    it "deletes the runner" do
      slave.should_receive(:stop)
      slave.runners = { "runner_name" => Time.now }
      slave.unregister_runner("runner_name")
      slave.runners.should be_empty
    end
  end

  describe "#set_num_runners" do
    it "sets num_runners" do
      slave.should_receive(:start_runners)
      slave.set_num_runners("num_runners" => 10)
      slave.num_runners.should == 10
    end
  end
end
