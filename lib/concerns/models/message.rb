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
  #Use MessageCenter::Service.send_message instead.
  def deliver(recipients)
    #Sender receipt
    sender_receipt = self.receipts.create!({:receiver=>sender, :mailbox_type=>'sentbox', :is_read=>true})

    super(recipients, 'inbox')

    on_deliver_callback.call(self) if on_deliver_callback

    sender_receipt
  end

end
