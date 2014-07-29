module MessageCenter::Concerns::Models::Mailbox
  extend ActiveSupport::Concern

  included do
    attr_reader :messageable
  end

  #Initializer method
  def initialize(messageable)
    @messageable = messageable
  end

  #Returns the notifications for the messageable
  def notifications(options = {})
    scope = MessageCenter::Notification.recipient(messageable).order(:created_at => :desc)
    if options[:read] == false || options[:unread]
      scope = scope.unread
    end

    scope
  end

  #Returns the conversations for the messageable
  #
  #Options
  #
  #* :mailbox_type (required)
  #  * "inbox"
  #  * "sentbox"
  #  * "trash"
  #
  #* :read=false
  #* :unread=true
  #
  def conversations(options = {})
    scope = MessageCenter::Conversation.participant(messageable)
    scope = scope.where(:message_center_receipts => {:mailbox_type => options[:mailbox_type]}) if options[:mailbox_type]
    scope = scope.merge(MessageCenter::Receipt.not_trash.not_deleted) unless 'trash'==options[:mailbox_type]
    #conv = get_conversations(options[:mailbox_type])

    if options[:read] == false || options[:unread]
      scope = scope.merge(MessageCenter::Receipt.is_unread)
    end

    scope
  end

  #Returns the conversations in the inbox of messageable
  #
  #Same as conversations({:mailbox_type => 'inbox'})
  def inbox(options={})
    options = options.merge(:mailbox_type => 'inbox')
    conversations(options)
  end

  #Returns the conversations in the sentbox of messageable
  #
  #Same as conversations({:mailbox_type => 'sentbox'})
  def sentbox(options={})
    options = options.merge(:mailbox_type => 'sentbox')
    conversations(options)
  end

  #Returns the conversations in the trash of messageable
  #
  #Same as conversations({:mailbox_type => 'trash'})
  def trash(options={})
    options = options.merge(:mailbox_type => 'trash')
    conversations(options)
  end

  #Returns all the receipts of messageable, from Messages and Notifications
  def receipts(options = {})
    MessageCenter::Receipt.where(options).recipient(messageable).order(:created_at => :desc)
  end

  #Deletes all the messages in the trash of messageable. NOT IMPLEMENTED.
  def empty_trash(_options = {})
    #TODO
    false
  end

  #Returns if messageable is a participant of conversation
  def has_conversation?(conversation)
    conversation.is_participant?(messageable)
  end

  #Returns true if messageable has at least one trashed message of the conversation
  def is_trashed?(conversation)
    conversation.is_trashed?(messageable)
  end

  #Returns true if messageable has trashed all the messages of the conversation
  def is_completely_trashed?(conversation)
    conversation.is_completely_trashed?(messageable)
  end

  #Returns the receipts of object for messageable as a ActiveRecord::Relation
  #
  #Object can be:
  #* A Message
  #* A Notification
  #* A Conversation
  #
  #If object isn't one of the above, a nil will be returned
  def receipts_for(object)
    case object
      when MessageCenter::Message, MessageCenter::Notification
        object.receipt_for(messageable)
      when MessageCenter::Conversation
        object.receipts_for(messageable)
    end
  end

end
