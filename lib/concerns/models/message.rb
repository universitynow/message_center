module MessageCenter::Concerns::Models::Message
  extend ActiveSupport::Concern

  included do

    belongs_to :conversation, :validate => true, :autosave => true, :counter_cache => true
    validates :sender, :presence => true

    class_attribute :on_deliver_callback
    protected :on_deliver_callback
    scope :conversation, ->(conversation) { where(:conversation => conversation) }

    mount_uploader :attachment, AttachmentUploader if defined?(CarrierWave)
  end

  module ClassMethods
    #Sets the on deliver callback method.
    def on_deliver(callback_method)
      self.on_deliver_callback = callback_method
    end
  end

  #Delivers a Message. USE NOT RECOMENDED.
  #Use MessageCenter::Models::Message.send_message instead.
    def deliver(recipients, reply = false, should_clean = true)
      recipients = Array.wrap(recipients)
      self.clean if should_clean
      #Receiver receipts
      temp_receipts = recipients.map { |r| build_receipt(r, 'inbox') }

      #Sender receipt
      sender_receipt = build_receipt(sender, 'sentbox', true)

      temp_receipts << sender_receipt

      if temp_receipts.all?(&:save!)

        MessageCenter::MailDispatcher.new(self, recipients).call

        conversation.touch if reply

        on_deliver_callback.call(self) if on_deliver_callback
      end
      sender_receipt
    end

end
