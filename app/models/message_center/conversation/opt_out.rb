module MessageCenter
  class Conversation
    class OptOut < ActiveRecord::Base
      self.table_name = :message_center_conversation_opt_outs

      belongs_to :conversation, :class_name => "MessageCenter::Conversation"
      belongs_to :unsubscriber, :class_name => MessageCenter.messageable_class

      validates :unsubscriber, :presence => true

      scope :unsubscriber, lambda { |entity| where(:unsubscriber => entity) }

    end
  end
end
