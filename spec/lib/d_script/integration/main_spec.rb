require "spec_helper"

describe 'Main' do
  let(:root) { File.dirname(File.join(File.dirname(__FILE__), '..', '..')) }
  let(:script) { File.join(root, "fixtures", "integration_script.rb") }
  let(:output_dir) { File.join(root, "logs") }

  let(:name) { "integration_test" }
  let(:settings) do
    { driver: "ruby", url: "redis://localhost:6379", db: 0, timeout: 5 }
  end

  before(:each) do
    FileUtils.rm_rf("#{output_dir}/.", secure: true)
  end

  it 'runs the script from start_id to end_id' do
    pid = spawn("bin/d_script_master #{script} -n #{name} -s 1 -e 100 -S 10 -o #{output_dir}")
    spawn("bin/d_script_runners -n #{name} -N 2")
    Process.wait(pid)
    contents = Dir.foreach(output_dir).each_with_object("") do |f, str|
      next if f == '.' or f == '..'
      str << File.read(File.join(output_dir, f))
    end
    contents.should match /1 11/
    contents.should match /11 21/
    contents.should match /21 31/
    contents.should match /31 41/
    contents.should match /41 51/
    contents.should match /51 61/
    contents.should match /61 71/
    contents.should match /71 81/
    contents.should match /81 91/
    contents.should match /91 101/
  end

  xit 'survives a redis crash' do
    pid = spawn("bin/d_script_master #{script} -n #{name} -s 1 -e 100 -S 10 -o #{output_dir}")
    spawn("bin/d_script_runners -n #{name} -N 2")
    sleep 4
    redis_pid = `pgrep redis`
    Process.kill(9, redis_pid.to_i)
    sleep 2
    spawn("redis-server")
    Process.wait(pid)
    contents = Dir.foreach(output_dir).each_with_object("") do |f, str|
      next if f == '.' or f == '..'
      str << File.read(File.join(output_dir, f))
    end
    contents.should match /1 11/
    contents.should match /11 21/
    contents.should match /21 31/
    contents.should match /31 41/
    contents.should match /41 51/
    contents.should match /51 61/
    contents.should match /61 71/
    contents.should match /71 81/
    contents.should match /81 91/
    contents.should match /91 101/
  end
end
