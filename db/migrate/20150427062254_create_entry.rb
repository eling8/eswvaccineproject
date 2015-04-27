class CreateEntry < ActiveRecord::Migration
  def up
  	create_table :entries do |t|
  		t.string :message
  		t.string :sender
  	end
  end
 
  def down
  	drop_table :entries
  end
end
