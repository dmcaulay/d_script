require "spec_helper"

RSpec.describe DScript::Base do
  let(:d_script) { DScriptTest.new("test") }

  describe '#ch_name' do
    it 'has an :id suffix if :id is present' do
      expect(d_script.ch_name("foo", 1)).to eql("test-foo-1")
    end

    it 'does not use an :id suffix if it is not present'  do
      expect(d_script.ch_name("foo")).to eql("test-foo")
    end
  end

  describe '#d_emit' do
    it "emits event over the redis subscription" do
      expect(d_script).to receive(:shutdown)
      d_script.start
      expect(d_script.payload).to eql({ "event" => "test", "payload" => "test data" })
    end
  end

  class DScriptTest < DScript::Base
    attr_accessor :payload, :failed
    alias_method :name, :base_name

    on :started, :init
    on :test, :a_method
    on :stopped, :shutdown

    def init(_)
      d_emit(name, {event: "test", payload: "test data"})
    end

    def shutdown(_)
    end

    def a_method(payload)
      @payload = payload
      stop
    end
  end

end
