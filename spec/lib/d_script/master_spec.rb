require 'spec_helper'

describe DScript::Master do
  let(:settings) do
    { driver: "hiredis", url: "redis://localhost:6379", db: 0, timeout: 5 }
  end
  let(:master) { DScript::Master.new("test", settings) }

  describe "#done?" do
    it "is true if current_id is greater than end_id" do
      master.current_id = 10
      master.end_id = 9
      master.should be_done
    end

    it "is true if current_id equals end_id" do
      master.current_id = 10
      master.end_id = 10
      master.should be_done
    end
  end

  describe "#next_end_id" do
    it "is current_id + block_size" do
      master.current_id = 10
      master.block_size = 12
      master.next_end_id.should == 22
    end

    it "increments current_id" do
      master.current_id = 10
      master.block_size = 12
      master.next_end_id
      master.current_id.should == 22
    end
  end

  describe "#next_block" do
    it "the next block to be processed" do
      master.current_id = 10
      master.block_size = 12
      master.next_block.should == { event: "next_block", start_id: 10, end_id: 22 }
    end
  end

  describe "#run" do
    before(:each) do
      master.should_receive(:start)
      master.run('test.rb', 1, 100, 10)
    end

    it "initializes the master" do
      master.script.should == 'test.rb'
      master.start_id.should == 1
      master.end_id.should == 100
      master.block_size.should == 10
      master.runners.should == {}
    end
  end

  describe "#runner_ready" do
    describe "when done? is true" do
      it "sends done to the runner channel" do
        master.should_receive(:done?).and_return(true)
        master.should_receive(:unregister_runner).with("runner_name")
        master.should_receive(:d_emit).with("runner_name", event: "done", "name" => "runner_name")
        master.runner_ready("name" => "runner_name")
      end
    end

    describe "when done? is false" do
      it "emits the next_block" do
        master.runners = {}
        master.current_id = 10
        master.block_size = 12
        master.should_receive(:done?).and_return(false)
        master.should_receive(:d_emit)
          .with("runner_name", event: "next_block", start_id: 10, end_id: 22, "name" => "runner_name")
        master.runner_ready("name" => "runner_name")
      end
    end
  end
end
