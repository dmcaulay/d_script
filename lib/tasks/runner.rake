namespace :d_script do
  task :runner, :name, :script, :output_file do |t, args|
    name = args[:name]
    script = args[:script]
    output_file = args[:output_file]

    puts "d_script:runner started with name=#{name} script=#{script} output_file=#{output_file}"

    runner = DScript::Runner.new(name, REDIS_SETTINGS)
    runner.run(script, output_file)

    puts "done"
  end
end
