class AddEntry < ActiveRecord::Migration
  def up
  	entry = Entry.new(:message => "testing", :sender => "16307308410", :temperature => "96 82 21 48 29", :current => "18", :voltage => "19", :date_time => DateTime.now)
  	entry.save

	entry = Entry.new(:message => "testing2", :sender => "16307308410", :temperature => "96 82 21 48 29 18 94 24", :current => "28", :voltage => "59", :date_time => DateTime.now)  	
	entry.save
  end

  def down
  	Entry.delete_all
  end
end
