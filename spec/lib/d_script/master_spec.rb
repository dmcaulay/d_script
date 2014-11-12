require 'spec_helper'

RSpec.describe DScript::Master do
  let(:settings) do
    { driver: "ruby", url: ENV['REDIS_URL'] || "redis://localhost:6379", db: 0, timeout: 5 }
  end
  let(:master) { DScript::Master.new("test", settings) }

  describe "#done?" do
    it "is true if current_id is greater than or equals to end_id" do
      master.current_id = 10
      master.end_id = 9
      expect(master).to be_done
      master.end_id = 10
      expect(master).to be_done
    end

    it "is false if current_id < end_id" do
      master.current_id = 9
      master.end_id = 10
      expect(master).not_to be_done
    end
  end

  describe "#next_end_id" do
    it "is current_id + block_size" do
      master.current_id = 10
      master.block_size = 12
      expect(master.next_end_id).to eql(22)
    end

    it "increments current_id" do
      master.current_id = 10
      master.block_size = 12
      master.next_end_id
      expect(master.current_id).to eql(22)
    end
  end

  describe "#next_block" do
    it "the next block to be processed" do
      master.current_id = 10
      master.block_size = 12
      expect(master.next_block).to eql({ event: "next_block", start_id: 10, end_id: 22 })
    end
  end

  describe "#run" do
    before(:each) do
      expect(master).to receive(:start)
      master.run(script: 'test.rb', output_dir: '/home/bzanchet', start_id: 1, end_id: 100, block_size: 10)
    end

    it "initializes the master" do
      expect(master.script).to eql('test.rb')
      expect(master.start_id).to eql(1)
      expect(master.end_id).to eql(100)
      expect(master.block_size).to eql(10)
      expect(master.runners).to eql({ })
    end
  end

  describe "#runner_ready" do
    describe "when done? is true" do
      it "sends done to the runner channel" do
        expect(master).to receive(:done?).and_return(true)
        expect(master).to receive(:unregister_runner).with("runner_name")
        expect(master).to receive(:d_emit).with("runner_name", event: "done", "name" => "runner_name")
        master.runner_ready("name" => "runner_name")
      end
    end

    describe "when done? is false" do
      it "emits the next_block" do
        master.runners = {}
        master.current_id = 10
        master.block_size = 12
        expect(master).to receive(:done?).and_return(false)
        expect(master).to receive(:d_emit)
          .with("runner_name", event: "next_block", start_id: 10, end_id: 22, "name" => "runner_name")
        master.runner_ready("name" => "runner_name")
      end
    end
  end

  describe 'runners' do
    before(:each) do
      master.runners = {}
    end

    describe "#register_runner" do
      it "sends the script to the runner" do
        expect(master).to receive(:d_emit).with("runner_name", event: "registered", script: "test.rb", output_dir: "/home/bzanchet")
        master.script = "test.rb"
        master.output_dir = "/home/bzanchet"
        master.register_runner("name" => "runner_name")
      end
    end

    describe "#unregister_runner" do
      it "deletes the runner" do
        expect(master).to receive(:stop)
        master.runners["runner_name"] = Time.now
        master.unregister_runner("runner_name")
        expect(master.runners).to be_empty
      end
    end

    it "sets up the register event" do
      expect(master).to receive(:register_runner)
      master.emit(:register, event: "register")
    end
  end
end
