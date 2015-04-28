class AddEntry < ActiveRecord::Migration
  def up
  	entry = Entry.new(:message => "sample message", :sender => "sample sender", :temperature => "sample temperature", :current => "sample temperature", :voltage => "sample voltage", :date_time => "2015-04-27 14:02:00")
  	entry.save
  end

  def down
  	Entry.delete_all
  end
end
