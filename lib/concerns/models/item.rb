module MessageCenter::Concerns::Models::Item
  extend ActiveSupport::Concern

  included do
    attr_writer :recipients
    attr_accessible :body, :subject, :global, :expires if MessageCenter.protected_attributes?

    belongs_to :sender, :class_name => MessageCenter.messageable_class
    has_many :receipts, :dependent => :destroy, :class_name => "MessageCenter::Receipt"

    validates :subject, :presence => true,
                        :length => { :maximum => MessageCenter.subject_max_length }
    validates :body,    :presence => true,
                        :length => { :maximum => MessageCenter.body_max_length }

    scope :recipient, lambda { |recipient|
      joins(:receipts).merge(MessageCenter::Receipt.recipient(recipient))
    }
    scope :not_trashed, lambda {
      joins(:receipts).where('message_center_receipts.trashed' => false)
    }
    scope :unread,  lambda {
      joins(:receipts).where('message_center_receipts.is_read' => false)
    }
    scope :global, lambda { where(:global => true) }
    scope :expired, lambda { where("message_center_items.expires < ?", Time.now) }
    scope :unexpired, lambda {
      where("message_center_items.expires is NULL OR message_center_items.expires > ?", Time.now)
    }

  end

  def expired?
    expires.present? && (expires < Time.now)
  end

  def expire!
    unless expired?
      expire
      save
    end
  end

  def expire
    unless expired?
      self.expires = Time.now - 1.second
    end
  end

  #Delivers a Notification. USE NOT RECOMENDED.
  #Use MessageCenter::Models::Message.notify and Notification.notify_all instead.
  def deliver(should_clean = true, send_mail = true)
    clean if should_clean
    temp_receipts = recipients.map { |r| build_receipt(r, nil, false) }

    if temp_receipts.all?(&:valid?)
      temp_receipts.each(&:save!)   #Save receipts
      MessageCenter::MailDispatcher.new(self, recipients).call if send_mail
      self.recipients = nil
    end

    return temp_receipts if temp_receipts.size > 1
    temp_receipts.first
  end

  #Returns the recipients of the Notification
  def recipients
    return Array.wrap(@recipients) unless @recipients.blank?
    @recipients = receipts.map { |receipt| receipt.receiver }
  end

  #Returns the receipt for the participant
  def receipt_for(participant)
    MessageCenter::Receipt.notification(self).recipient(participant)
  end

  #Returns the receipt for the participant. Alias for receipt_for(participant)
  def receipts_for(participant)
    receipt_for(participant)
  end

  #Returns if the participant have read the Notification
  def is_unread?(participant)
    return false if participant.nil?
    !receipt_for(participant).first.is_read
  end

  def is_read?(participant)
    !is_unread?(participant)
  end

  #Returns if the participant have trashed the Notification
  def is_trashed?(participant)
    return false if participant.nil?
    receipt_for(participant).first.trashed
  end

  #Returns if the participant have deleted the Notification
  def is_deleted?(participant)
    return false if participant.nil?
    return receipt_for(participant).first.deleted
  end

  #Mark the notification as read
  def mark_as_read(participant)
    return if participant.nil?
    receipt_for(participant).mark_as_read
  end

  #Mark the notification as unread
  def mark_as_unread(participant)
    return if participant.nil?
    receipt_for(participant).mark_as_unread
  end

  #Move the notification to the trash
  def move_to_trash(participant)
    return if participant.nil?
    receipt_for(participant).move_to_trash
  end

  #Takes the notification out of the trash
  def untrash(participant)
    return if participant.nil?
    receipt_for(participant).untrash
  end

  #Mark the notification as deleted for one of the participant
  def mark_as_deleted(participant)
    return if participant.nil?
    return receipt_for(participant).mark_as_deleted
  end

  #Sanitizes the body and subject
  def clean
    self.subject = sanitize(subject) if subject
    self.body    = sanitize(body)
  end

  #Returns notified_object. DEPRECATED
  def object
    warn "DEPRECATION WARNING: use 'notify_object' instead of 'object' to get the object associated with the Notification"
    notified_object
  end

  def sanitize(text)
    ::MessageCenter::Cleaner.instance.sanitize(text)
  end

  private

  def build_receipt(receiver, mailbox_type, is_read = false)
    MessageCenter::Receipt.new(
      :item         => self,
      :mailbox_type => mailbox_type || 'inbox',
      :receiver     => receiver,
      :is_read      => is_read
    )
  end

end
