class ChangeEventsLogPayloadColumn < ActiveRecord::Migration
  def up
    change_column :'denormalization.events_log', :payload, :text
  end

  def down
    change_column :'denormalization.events_log', :payload, :string, limit: 512
  end
end
