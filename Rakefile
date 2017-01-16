require 'data_mapper'
require './web.rb'

namespace :db do
  desc "Non destructive upgrade"
  task :auto_upgrade do
    DataMapper.auto_upgrade!
    puts "Auto-upgrade complete (no data loss), Wayne Rumble was here. LOL"
  end


  desc "Destructive upgrade"
  task :auto_migrate do
    DataMapper.auto_migrate!
    puts "Auto-migrate complete (data was lost), Wayne Rumble was here. LOL"
  end
end
