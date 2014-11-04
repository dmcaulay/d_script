require 'spec_helper'

describe DScript::Runners do
  let(:settings) do
    { driver: "ruby", url: "redis://localhost:6379", db: 0, timeout: 5 }
  end
  let(:runners) { TestRunners.new("test", settings) }

  describe "#register_runner" do
    it "sends the script to the runner" do
      runners.should_receive(:d_emit).with("runner_name", event: "registered", script: "test.rb", output_dir: "/home/bzanchet")
      runners.script = "test.rb"
      runners.output_dir = "/home/bzanchet"
      runners.register_runner("name" => "runner_name")
    end
  end

  describe "#unregister_runner" do
    it "deletes the runner" do
      runners.should_receive(:stop)
      runners.runners["runner_name"] = Time.now
      runners.unregister_runner("runner_name")
      runners.runners.should be_empty
    end
  end

  it "sets up the register event" do
    runners.should_receive(:register_runner)
    runners.emit(:register, event: "register")
  end

  class TestRunners < DScript::Base
    include DScript::Runners

    attr_accessor :script, :output_dir

    def runners
      @runners ||= {}
    end
  end

end
