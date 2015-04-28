class CreateEntry < ActiveRecord::Migration
  def up
  	create_table :entries do |t|
  		t.string :temperature
  		t.string :current
  		t.string :voltage
  		t.string :message
  		t.string :sender
  		t.datetime :date_time
  		t.timestamps null: false
  	end
  end
 
  def down
  	drop_table :entries
  end
end
