require 'spec_helper'

describe DScript::Runners do
  let(:settings) do
    { driver: "ruby", url: "redis://localhost:6379", db: 0, timeout: 5 }
  end
  let(:master) { TestMaster.new("test", settings) }

  describe "#register_runner" do
    it "sends the script to the runner" do
      master.should_receive(:d_emit).with("runner_name", event: "registered", script: "test.rb", output_dir: "/home/bzanchet")
      master.script = "test.rb"
      master.output_dir = "/home/bzanchet"
      master.register_runner("name" => "runner_name")
    end
  end

  describe "#unregister_runner" do
    it "deletes the runner" do
      master.should_receive(:stop)
      master.runners["runner_name"] = Time.now
      master.unregister_runner("runner_name")
      master.runners.should be_empty
    end
  end

  it "sets up the register event" do
    master.should_receive(:register_runner)
    master.emit(:register, event: "register")
  end

  class TestMaster < DScript::Base
    include DScript::Runners

    attr_accessor :script, :output_dir

    def runners
      @runners ||= {}
    end
  end

end
