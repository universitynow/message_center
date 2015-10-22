class AddBulkToMessageCenterItem < ActiveRecord::Migration
  def up
    add_column :message_center_items, :bulk, :boolean, :default => false
  end

  def down
    remove_column :message_center_items, :bulk
  end
end