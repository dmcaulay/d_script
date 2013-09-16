class CurrentDScript
  def self.run(start_id, end_id, file)
    User.where(["id >= ? AND id < ?", start_id, end_id]).find_each do |user|
      puts "processing #{user.id}"
      file.puts "id #{user.id} email #{user.email}"
      sleep(1)
    end
  end
end
