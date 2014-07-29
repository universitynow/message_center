module MessageCenter::Concerns::Models::Conversation
  extend ActiveSupport::Concern

  included do

    has_many :opt_outs, :dependent => :destroy
    has_many :messages, :dependent => :destroy
    has_many :receipts, :through => :messages

    has_many :receivers, -> { uniq }, :through => :receipts
    alias_method :recipients, :receivers
    alias_method :participants, :receivers

    validates :subject, :presence => true,
              :length => { :maximum => MessageCenter.subject_max_length }

    before_validation :clean

    scope :participant, ->(participant) {
      joins(:receipts).merge(MessageCenter::Receipt.recipient(participant)).
          order(:updated_at => :desc).uniq
    }
  end

  #Mark the conversation as read for one of the participants
  def mark_as_read(participant, is_read=true)
    return unless participant
    receipts_for(participant).mark_as_read(is_read)
  end

  #Mark the conversation as starred for one of the participants
  def mark_as_starred(participant)
    return unless participant
    receipts_for(participant).each{|r| r.mark_as_starred}
  end

  #Mark the conversation as unstarred for one of the participants
  def mark_as_unstarred(participant)
    return unless participant
    receipts_for(participant).each{|r| r.mark_as_unstarred}
  end

  #Move the conversation to the trash for one of the participants
  def move_to_trash(participant, trashed=true)
    return unless participant
    receipts_for(participant).move_to_trash(trashed)
  end

  #Mark the conversation as deleted for one of the participants
  def mark_as_deleted(participant)
    return unless participant
    deleted_receipts = receipts_for(participant).mark_as_deleted
    if is_orphaned?
      destroy
    else
      deleted_receipts
    end
  end

  #Originator of the conversation.
  def originator
    @originator ||= original_message.sender
  end

  #First message of the conversation.
  def original_message
    @original_message ||= messages.order('created_at').first
  end

  #Sender of the last message.
  def last_sender
    @last_sender ||= last_message.sender
  end

  #Last message in the conversation.
  def last_message
    @last_message ||= messages.order('created_at DESC').first
  end

  #Returns the receipts of the conversation for one participants
  def receipts_for(participant)
    MessageCenter::Receipt.conversation(self).recipient(participant)
  end

  #Returns true if the messageable is a participant of the conversation
  def is_participant?(participant)
    return false unless participant
    receipts_for(participant).any?
  end

  #Adds a new participant to the conversation
  def add_participant(participant)
    messages.each do |message|
      MessageCenter::Receipt.create(
                                            :item         => message,
                                            :receiver     => participant,
                                            :updated_at   => message.updated_at,
                                            :created_at   => message.created_at
                                        )
    end
  end

  #Returns true if the participant has at least one trashed message of the conversation
  def is_trashed?(participant)
    return false unless participant
    receipts_for(participant).trash.count != 0
  end

  #Returns true if the participant has deleted the conversation
  def is_deleted?(participant)
    return false unless participant
    receipts_for(participant).deleted.count == receipts_for(participant).count
  end

  #Returns true if both participants have deleted the conversation
  def is_orphaned?
    participants.reduce(true) do |is_orphaned, participant|
      is_orphaned && is_deleted?(participant)
    end
  end

  #Returns true if the participant has trashed all the messages of the conversation
  def is_completely_trashed?(participant)
    return false unless participant
    receipts_for(participant).trash.count == receipts_for(participant).count
  end

  def is_read?(participant)
    !is_unread?(participant)
  end

  #Returns true if the participant has at least one unread message of the conversation
  def is_unread?(participant)
    return false unless participant
    receipts_for(participant).not_trash.is_unread.count != 0
  end

  # Creates a opt out object
  # because by default all particpants are opt in
  def opt_out(participant)
    return unless has_subscriber?(participant)
    opt_outs.create(:unsubscriber => participant)
  end

  # Destroys opt out object if any
  # a participant outside of the discussion is, yet, not meant to optin
  def opt_in(participant)
    opt_outs.unsubscriber(participant).destroy_all
  end

  # tells if participant is opt in
  def has_subscriber?(participant)
    !opt_outs.unsubscriber(participant).any?
  end

  protected

  #Use the default sanitize to clean the conversation subject
  def clean
    self.subject = sanitize subject
  end

  def sanitize(text)
    ::MessageCenter::Cleaner.instance.sanitize(text)
  end

end
