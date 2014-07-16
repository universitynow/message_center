module MessageCenter
  class Conversation
    class OptOut < ActiveRecord::Base
      self.table_name = :message_center_conversation_opt_outs

      belongs_to :conversation, :class_name  => "MessageCenter::Conversation"
      belongs_to :unsubscriber, :polymorphic => true

      validates :unsubscriber, :presence => true

      scope :unsubscriber, lambda { |entity| where(:unsubscriber_type => entity.class.base_class.name, :unsubscriber_id => entity.id) }

    end
  end
end
