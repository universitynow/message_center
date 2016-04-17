# This migration comes from message_center (originally 20151022110105)
class AddBulkToMessageCenterItem < ActiveRecord::Migration
  def up
    add_column :message_center_items, :bulk, :boolean, :default => false
  end

  def down
    remove_column :message_center_items, :bulk
  end
end