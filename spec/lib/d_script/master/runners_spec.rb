require 'spec_helper'

describe DScript::Runners do
  let(:settings) do
    { driver: "ruby", url: "redis://localhost:6379", db: 0, timeout: 5 }
  end
  let(:slave) { slave = TestMaster.new("test", settings) }

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
      slave.runners["runner_name"] = Time.now
      slave.unregister_runner("runner_name")
      slave.runners.should be_empty
    end
  end

  class TestMaster < DScript::Base
    include DScript::Runners

    attr_accessor :script

    def runners
      @runners ||= {}
    end
  end

end
