module MessageCenter::Concerns::Models::Receipt
  extend ActiveSupport::Concern

  included do

    belongs_to :item
    # alias for backwards compatibility
    alias_method :notification, :item
    belongs_to :message, :foreign_key => 'item_id'

    belongs_to :receiver, :class_name => MessageCenter.messageable_class
    validates :receiver, :presence => true, :on => :create

    scope :recipient, ->(recipient) { where(:receiver => recipient) }
    scope :notifications_receipts, -> { joins(:item).merge(MessageCenter::Notification.all) }
    scope :messages_receipts, -> { joins(:item).merge(MessageCenter::Message.all) }
    scope :notification, ->(item) { where(:item => item) }
    scope :conversation, ->(conversation) {
      joins(:message).merge(MessageCenter::Message.conversation(conversation))
    }
    scope :sentbox, -> { where(:mailbox_type => 'sentbox') }
    scope :inbox, -> { where(:mailbox_type => 'inbox') }
    scope :trash, -> { where(:trashed => true, :deleted => false) }
    scope :not_trash, -> { where(:trashed => false) }
    scope :deleted, -> { where(:deleted => true) }
    scope :not_deleted, -> { where(:deleted => false) }
    scope :is_read, -> { where(:is_read => true) }
    scope :is_unread, -> { where(:is_read => false) }
    scope :starred, -> { where(:starred => true)}
    scope :unstarred, -> { where(:starred => false)}

    after_validation :remove_duplicate_errors
  end

  module ClassMethods
    #Marks all the receipts from the relation as read
    def mark_as_read(is_read=true)
      update_all({:is_read => is_read})
    end

    #Marks all the receipts from the relation as deleted
    def mark_as_deleted(deleted=true)
      update_all({:deleted => deleted})
    end

    #Marks all the receipts from the relation as trashed
    def move_to_trash(trashed=true)
      update_all({:trashed => trashed})
    end

    #Marks all the receipts from the relation as starred
    def mark_as_starred(starred=true)
      update_all({:starred => starred})
    end

    #Moves all the receipts from the relation to inbox
    def move_to_inbox
      update_all({:mailbox_type => :inbox, :trashed => false})
    end

    #Moves all the receipts from the relation to sentbox
    def move_to_sentbox
      update_all({:mailbox_type => :sentbox, :trashed => false})
    end

  end

  #Marks the receipt as deleted
  def mark_as_deleted(deleted=true)
    update_attributes(:deleted => deleted)
  end

  #Marks the receipt as read
  def mark_as_read(is_read=true)
    update_attributes(:is_read => is_read)
  end

  #Marks as starred
  def mark_as_starred(starred=true)
    update_attributes(:starred => starred)
  end

  #Marks the receipt as trashed
  def move_to_trash(trashed=true)
    update_attributes(:trashed => trashed)
  end

  #Moves the receipt to inbox
  def move_to_inbox
    update_attributes(:mailbox_type => :inbox, :trashed => false)
  end

  #Moves the receipt to sentbox
  def move_to_sentbox
    update_attributes(:mailbox_type => :sentbox, :trashed => false)
  end

  #Returns the conversation associated to the receipt if the item is a Message
  def conversation
    message.conversation if message.is_a? MessageCenter::Message
  end

  #Returns if the participant have read the Item
  def is_unread?
    !is_read
  end

  #Returns if the participant have trashed the Item
  def is_trashed?
    trashed
  end

  protected

  #Removes the duplicate error about not present subject from Conversation if it has been already
  #raised by Message
  def remove_duplicate_errors
    if errors['message_center_item.conversation.subject'].present? and errors['message_center_item.subject'].present?
      errors['message_center_item.conversation.subject'].each do |msg|
        errors['message_center_item.conversation.subject'].delete(msg)
      end
    end
  end

  if MessageCenter.search_enabled
    searchable do
      text :subject, :boost => 5 do
        message.subject if message
      end
      text :body do
        message.body if message
      end
      integer :receiver_id
    end
  end

end
