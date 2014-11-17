# DScript

[![Build Status](https://travis-ci.org/weheartit/d_script.svg?branch=master)](https://travis-ci.org/weheartit/d_script)

DScript allows you to load a script and distribute the processing across multiple runners on multiple servers. DScript uses Redis to keep track of the script progress and to communicate to the script runners.

## Installation

Add this line to your application's Gemfile:

    gem 'd_script'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install d_script

## Usage

d_script comes with 3 helper scripts that help you start and monitor the progress of your task.

### The Master

The master process keeps track of the progress and distributes the work to the slaves.

```
$ d_script_master [SCRIPT_FILE] [OPTIONS]

start the master process with the SCRIPT_FILE

options:
-n, --name
  the name of the job. this is used to keep track of progress and communicate with the runners.
-s, --start_id
  the start id for the script. d_script breaks the task up into smaller chunks. the start id tells the master process where it starrts.
-e, --end_id
  the end id for the script. this is used to determine when the script is complete.
-S, --block_size
  the size of each block to be processed. each block should take less than a minute to complete so the progress is updated at a reasonable rate.
-r, --redis
  the redis url for the script
-o, --output
  the directory for logging the progress and any errors that occur.

$ bundle exec d_script_master script/long_script.rb -n long_script -s 0 -e 11000000 -S 100 -o /script/output -r redis://localhost:6379
```

### The Runners

The runners script starts n runners that process each block. You usually run this once on each server processing the script.

```
$ d_script_runners [OPTIONS]

-n, --name
  the name of the job. this is used to connect to the master.
-N, --num_runners
  the number of runners to start on this server.
-e, --env
  the RAILS_ENV for each runner.
-r, --redis
  the redis url for the script.

$ bundle exec d_script_runners -n long_script -N 100 -e production -r redis://localhost:6379
```

### The Console

The console can be used to monitor the job, update the number of runners for a slave and reload the script on a runner.

```
$ d_script_console [OPTIONS]

-n, --name
  the name of the job. this is used to connect to the master, slave or runner.
-r, --redis
  the redis url for the script.

$ bundle exec d_script_console -n long_script -r redis://localhost:6379
```

The console runs the following commands.

```
# get the status of the current job
status

# get the status of a slave
status slave_id

# reload the script on a runner
reload runner_id

# change the number of runners on a slave
num_runners slave_id number_of_runners

# exit the console
exit
```

### The Runner

The runner processes are the ones doing all the work. They communicate to the master and let the master know when they are ready to process the next block. Each runner is a `rake` task that loads your Rails environment. The runners are never started manually. They are started by the runners command.

### The Script

The script defines the task that you are running. It needs to implement `CurrentDScript.run`. It is called from a `rake` task so your entire Rails environment is available from the script. Here's a simple example.

```rb
class CurrentDScript
  def self.run(start_id, end_id, output)
    User.where(["id >= ? AND id < ?", start_id, end_id]).find_each do |user|
      puts "processing #{user.id}"
      output.puts "id #{user.id} email #{user.email}"
      sleep(1)
    end
  end
end
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
