module MessageCenter::Concerns::Models::Message
  extend ActiveSupport::Concern

  included do

    belongs_to :conversation, :validate => true, :autosave => true, :counter_cache => true
    validates :sender, :presence => true

    scope :conversation, ->(conversation) { where(:conversation => conversation) }

    mount_uploader :attachment, AttachmentUploader if defined?(CarrierWave)
  end

  #Delivers a Message. USE NOT RECOMENDED.
  #Use MessageCenter::Service.send_message instead.
  def deliver(recipients)
    # Sender receipt - always created first
    self.receipts.create!({:receiver=>sender, :mailbox_type=>'sentbox', :is_read=>true})

    super(recipients, 'inbox')

  end

end
