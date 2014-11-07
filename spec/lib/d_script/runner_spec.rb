require 'spec_helper'

RSpec.describe DScript::Runner do
  let(:settings) do
    { driver: "ruby", url: ENV['REDIS_URL'] || "redis://localhost:6379", db: 0, timeout: 5 }
  end
  let(:runner) { DScript::Runner.new("test", settings) }

  let(:root) { File.dirname(__FILE__) }
  let(:script_path) { File.join(root, "fixtures", "test_script.rb") }
  let(:output_dir) { File.join(root, "logs") }
  let(:output_file) { File.join(output_dir, "#{runner.name}.txt") }

  let(:script_payload) { { "script" => script_path, "output_dir" => output_dir } }

  before(:each) do
    allow_any_instance_of(Redis).to receive(:incr).and_return(1)
    FileUtils.rm_rf("#{output_dir}/.", secure: true)
    Object.send(:remove_const, :CurrentDScript) if defined?(CurrentDScript)
    allow(runner).to receive(:d_emit)
   end

  describe "#name" do
    it "returns the channel name for the runner" do
      expect(runner.name).to eql("test-runner-1")
    end
  end

  describe "#master_ch" do
    it "returns the name of the master channel" do
      expect(runner.master_ch).to eql('test-master')
    end
  end

  describe "#set_script" do
    it "loads the script" do
      expect(defined?(CurrentDScript)).to be_nil
      expect(runner.script).to be_nil
      runner.set_script(script_payload)
      expect(runner.script).not_to be_nil
      expect(defined?(CurrentDScript)).to eql("constant")
    end

    it "opens the output file" do
      expect(File.exists?(output_file)).to eql(false)
      runner.set_script(script_payload)
      expect(File.exists?(output_file)).to eql(true)
    end

    it "tells the master that it's ready" do
      expect(runner).to receive(:ready)
      runner.set_script(script_payload)
    end
  end

  describe "#next_block" do
    let(:block_payload) { { "start_id" => 1, "end_id" => 10 } }
    before(:each) do
      runner.set_script(script_payload)
    end

    it "process the entry and outpus information" do
      runner.next_block(block_payload)
      f = File.open(output_file, 'r')
      expect(f.gets).to eql("processing {\"start_id\"=>1, \"end_id\"=>10}\n")
      expect(f.gets).to eql("running 1 10\n")
      expect(f.gets).to eql("finished {\"start_id\"=>1, \"end_id\"=>10}\n")
      expect(f.gets).to be_nil
    end

    it "handles errors" do
      expect(CurrentDScript).to receive(:run).and_raise("BOOM!")
      runner.next_block(block_payload)
      f = File.open(output_file, 'r')
      expect(f.gets).to eql("processing {\"start_id\"=>1, \"end_id\"=>10}\n")
      expect(f.gets).to eql("error running {\"start_id\"=>1, \"end_id\"=>10}\n")
      expect(f.gets).to eql("RuntimeError: BOOM!\n")
    end

    it "allows reload" do
      allow(CurrentDScript).to receive(:run).and_raise("BOOM!")
      runner.next_block(block_payload)
      allow(CurrentDScript).to receive(:run).and_call_original
      runner.reload(nil)
      f = File.open(output_file, 'r')
      begin
        line = f.gets
      end while line != "reloading {\"start_id\"=>1, \"end_id\"=>10}\n" && line != nil
      expect(f.gets).to eql("running 1 10\n")
      expect(f.gets).to eql("finished {\"start_id\"=>1, \"end_id\"=>10}\n")
      expect(f.gets).to be_nil
    end
  end
end
