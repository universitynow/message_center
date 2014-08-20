module MessageCenter::Concerns::Models::Message
  extend ActiveSupport::Concern

  included do

    belongs_to :conversation, :validate => true, :autosave => true, :counter_cache => true
    validates :sender, :presence => true, :on => :create

    scope :conversation, ->(conversation) { where(:conversation => conversation) }

    mount_uploader :attachment, AttachmentUploader if defined?(CarrierWave)
  end

  def create_sender_receipt
    self.receipts.create!({:receiver=>sender, :mailbox_type=>'sentbox', :is_read=>true})
  end

  #Delivers a Message. USE NOT RECOMENDED.
  #Use MessageCenter::Service.send_message instead.
  def deliver(recipients, mailbox_type='inbox')
    super
  end

end
