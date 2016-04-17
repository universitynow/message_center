# This migration comes from message_center (originally 20160417000000)
class AddSenderIdToMessageCenterReceipt < ActiveRecord::Migration
  def up
    add_column :message_center_receipts, :sender_id, :integer
    add_index :message_center_receipts, [:sender_id, :receiver_id]

    # Warning: This query can take a while to execute (~2 minutes) so it should be done outside the migration
    puts "You should execute the following query to populate sender_id on message_center receipts"
    puts "  update message_center_receipts mr set sender_id = mi.sender_id from message_center_items mi where mr.item_id=mi.id;"
  end

  def down
    remove_column :message_center_receipts, :sender_id
  end
end
