class AddConversationOptout < ActiveRecord::Migration
  def self.up
    create_table :message_center_conversation_opt_outs do |t|
      t.integer :unsubscriber_id, :null => false
      t.references :conversation
    end
    add_foreign_key "message_center_conversation_opt_outs", "message_center_conversations", :name => "mb_opt_outs_on_conversations_id", :column => "conversation_id"
  end

  def self.down
    remove_foreign_key "message_center_conversation_opt_outs", :name => "mb_opt_outs_on_conversations_id"
    drop_table :message_center_conversation_opt_outs
  end
end
