module MessageCenter::Concerns::Models::Notification
  extend ActiveSupport::Concern

  included do
    belongs_to :notified_object, :polymorphic => :true
    scope :with_object, ->(obj) { where(:notified_object => obj) }
    scope :global, -> { where(:global => true) }
    scope :expired, -> { where('message_center_items.expires_at < ?', Time.now) }
    scope :unexpired, -> { where('expires_at is NULL OR expires_at > ?', Time.now) }
  end

  def expired?
    expires_at.present? && (expires_at < Time.now)
  end

  def expire!
    unless expired?
      expire
      save
    end
  end

  def expire
    unless expired?
      self.expires_at = Time.now - 1.second
    end
  end

end
