module MessageCenter::Concerns::Models::Notification
  extend ActiveSupport::Concern

  included do
    belongs_to :notified_object, :polymorphic => :true
    scope :with_object, ->(obj) { where(:notified_object => obj) }
  end

end
