module MessageCenter::Concerns::Models::Receipt
  extend ActiveSupport::Concern

  included do
    attr_accessible :trashed, :is_read, :deleted if MessageCenter.protected_attributes?

    store_accessor :properties, :label, :starred

    belongs_to :item, :class_name => "MessageCenter::Item", :validate => true, :autosave => true
    # TODO: for backwards compatibility - possibly remove :notification and :message or alias them both
    alias_method :notification, :item
    belongs_to :receiver, :class_name => MessageCenter.messageable_class
    belongs_to :message, :class_name => "MessageCenter::Message", :foreign_key => "item_id"

    validates_presence_of :receiver

    scope :recipient, lambda { |recipient| where(:receiver => recipient) }
    scope :notifications_receipts, lambda { joins(:item).where('message_center_items.type' => 'MessageCenter::Notification') }
    scope :messages_receipts, lambda { joins(:item).where('message_center_items.type' => 'MessageCenter::Message') }
    scope :notification, lambda { |item|
      where(:item_id => item.id)
    }
    scope :conversation, lambda { |conversation|
      joins(:message).where('message_center_items.conversation_id' => conversation.id)
    }
    scope :sentbox, lambda { where(:mailbox_type => "sentbox") }
    scope :inbox, lambda { where(:mailbox_type => "inbox") }
    scope :trash, lambda { where(:trashed => true, :deleted => false) }
    scope :not_trash, lambda { where(:trashed => false) }
    scope :deleted, lambda { where(:deleted => true) }
    scope :not_deleted, lambda { where(:deleted => false) }
    scope :is_read, lambda { where(:is_read => true) }
    scope :is_unread, lambda { where(:is_read => false) }

    after_validation :remove_duplicate_errors
  end


  module ClassMethods
    #Marks all the receipts from the relation as read
    def mark_as_read(options={})
      update_receipts({:is_read => true}, options)
    end

    #Marks all the receipts from the relation as unread
    def mark_as_unread(options={})
      update_receipts({:is_read => false}, options)
    end

    #Marks all the receipts from the relation as trashed
    def move_to_trash(options={})
      update_receipts({:trashed => true}, options)
    end

    #Marks all the receipts from the relation as not trashed
    def untrash(options={})
      update_receipts({:trashed => false}, options)
    end

    #Marks the receipt as deleted
    def mark_as_deleted(options={})
      update_receipts({:deleted => true}, options)
    end

    #Marks the receipt as not deleted
    def mark_as_not_deleted(options={})
      update_receipts({:deleted => false}, options)
    end

    #Moves all the receipts from the relation to inbox
    def move_to_inbox(options={})
      update_receipts({:mailbox_type => :inbox, :trashed => false}, options)
    end

    #Moves all the receipts from the relation to sentbox
    def move_to_sentbox(options={})
      update_receipts({:mailbox_type => :sentbox, :trashed => false}, options)
    end

    #This methods helps to do a update_all with table joins, not currently supported by rails.
    #According to the github ticket https://github.com/rails/rails/issues/522 it should be
    #supported with 3.2.
    def update_receipts(updates,options={})
      ids = where(options).map { |rcp| rcp.id }
      unless ids.empty?
        conditions = [""].concat(ids)
        condition = "id = ? "
        ids.drop(1).each do
          condition << "OR id = ? "
        end
        conditions[0] = condition
        MessageCenter::Receipt.except(:where).except(:joins).where(conditions).update_all(updates)
      end
    end
  end

  #Marks the receipt as deleted
  def mark_as_deleted
    update_attributes(:deleted => true)
  end

  #Marks the receipt as not deleted
  def mark_as_not_deleted
    update_attributes(:deleted => false)
  end

  #Marks the receipt as read
  def mark_as_read
    update_attributes(:is_read => true)
  end

  #Marks the receipt as unread
  def mark_as_unread
    update_attributes(:is_read => false)
  end

  #Marks as starred
  def mark_as_starred
    update_attributes(:starred => true)
  end

  #Marks as unstarred
  def mark_as_unstarred
    update_attributes(:starred => false)
  end

  #Marks the receipt as trashed
  def move_to_trash
    update_attributes(:trashed => true)
  end

  #Marks the receipt as not trashed
  def untrash
    update_attributes(:trashed => false)
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
    if errors["message_center_item.conversation.subject"].present? and errors["message_center_item.subject"].present?
      errors["message_center_item.conversation.subject"].each do |msg|
        errors["message_center_item.conversation.subject"].delete(msg)
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
