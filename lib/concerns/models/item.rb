module MessageCenter::Concerns::Models::Item
  extend ActiveSupport::Concern

  included do
    belongs_to :sender, :class_name => MessageCenter.messageable_class
    has_many :receipts, :dependent => :destroy
    has_many :receivers, :through => :receipts
    alias_method :recipients, :receivers

    validates :subject, :presence => true,
                        :length => { :maximum => MessageCenter.subject_max_length }
    validates :body,    :presence => true,
                        :length => { :maximum => MessageCenter.body_max_length }

    scope :recipient, ->(recipient) { joins(:receipts).merge(MessageCenter::Receipt.recipient(recipient)) }
    scope :not_trashed, -> { joins(:receipts).merge(MessageCenter::Receipt.not_trash) }
    scope :unread, -> { joins(:receipts).merge(MessageCenter::Receipt.is_unread) }
  end

  #Delivers a Notification. USE NOT RECOMENDED.
  #Use MessageCenter::Service.notify instead
  def deliver(recipients, send_mail = true)
    recipients = Array.wrap(recipients)

    #Receiver receipts
    recipients.each do |recipient|
      self.receipts.create!({:receiver=>recipient})
    end

    MessageCenter::MailDispatcher.new(self, recipients).call if send_mail

    return self.receipts if self.receipts.size > 1
    self.receipts.first
  end

  #Returns the receipt for the participant
  def receipt_for(participant)
    MessageCenter::Receipt.notification(self).recipient(participant)
  end

  #Mark the notification as read
  def mark_as_read(participant, is_read=true)
    return if participant.nil?
    receipt_for(participant).mark_as_read(is_read)
  end

  #Move the notification to the trash
  def move_to_trash(participant, trashed=true)
    return if participant.nil?
    receipt_for(participant).move_to_trash(trashed)
  end

  #Mark the notification as deleted for one of the participant
  def mark_as_deleted(participant)
    return if participant.nil?
    receipt_for(participant).mark_as_deleted
  end

  #Sanitizes the body and subject
  def clean
    self.subject = sanitize(subject) if subject
    self.body    = sanitize(body)
  end

  def sanitize(text)
    ::MessageCenter::Cleaner.instance.sanitize(text)
  end

end
