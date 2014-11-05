require 'spec_helper'

describe DScript::Runner do
  let(:settings) do
    { driver: "ruby", url: "redis://localhost:6379", db: 0, timeout: 5 }
  end
  let(:runner) { DScript::Runner.new("test", settings) }

  let(:root) { File.dirname(__FILE__) }
  let(:script_path) { File.join(root, "fixtures", "test_script.rb") }
  let(:output_dir) { File.join(root, "logs") }
  let(:output_file) { File.join(output_dir, "#{runner.name}.txt") }

  let(:script_payload) { { "script" => script_path, "output_dir" => output_dir } }

  before(:each) do
    Redis.any_instance.stub(:incr).and_return(1)
    FileUtils.rm_rf("#{output_dir}/.", secure: true)
    Object.send(:remove_const, :CurrentDScript) if defined?(CurrentDScript)
   end

  describe "#name" do
    it "returns the channel name for the runner" do
      runner.name.should == "test-runner-1"
    end
  end

  describe "#master_ch" do
    it "returns the name of the master channel" do
      runner.master_ch.should == 'test-master'
    end
  end

  describe "#set_script" do
    it "loads the script" do
      defined?(CurrentDScript).should be_nil
      runner.script.should be_nil
      runner.set_script(script_payload)
      runner.script.should_not be_nil
      defined?(CurrentDScript).should == "constant"
    end

    it "opens the output file" do
      File.exists?(output_file).should be_false
      runner.set_script(script_payload)
      File.exists?(output_file).should be_true
    end

    it "tells the master that it's ready" do
      runner.should_receive(:ready)
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
      f.gets.should == "processing {\"start_id\"=>1, \"end_id\"=>10}\n"
      f.gets.should == "running 1 10\n"
      f.gets.should == "finished {\"start_id\"=>1, \"end_id\"=>10}\n"
      f.gets.should be_nil
    end

    it "handles errors" do
      CurrentDScript.should_receive(:run).and_raise("BOOM!")
      runner.next_block(block_payload)
      f = File.open(output_file, 'r')
      f.gets.should == "processing {\"start_id\"=>1, \"end_id\"=>10}\n"
      f.gets.should == "error running {\"start_id\"=>1, \"end_id\"=>10}\n"
      f.gets.should == "RuntimeError: BOOM!\n"
    end

    it "allows reload" do
      CurrentDScript.stub(:run).and_raise("BOOM!")
      runner.next_block(block_payload)
      CurrentDScript.stub(:run).and_call_original
      runner.reload(nil)
      f = File.open(output_file, 'r')
      begin
        line = f.gets
      end while line != "reloading {\"start_id\"=>1, \"end_id\"=>10}\n" && line != nil
      f.gets.should == "running 1 10\n"
      f.gets.should == "finished {\"start_id\"=>1, \"end_id\"=>10}\n"
      f.gets.should be_nil
    end
  end
end
