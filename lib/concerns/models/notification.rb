module MessageCenter::Concerns::Models::Notification
  extend ActiveSupport::Concern

  included do
    belongs_to :notified_object, :polymorphic => :true

    scope :with_object, ->(obj) { where(:notified_object => obj) }
  end

  module ClassMethods
    #Sends a Notification to all the recipients
    def notify_all(recipients, subject, body, obj = nil, sanitize_text = true, notification_code=nil, send_mail=true)
      notification = MessageCenter::Notification.new(
        :recipients        => recipients,
        :subject           => subject,
        :body              => body,
        :notified_object   => obj,
        :notification_code => notification_code
      )

      notification.deliver sanitize_text, send_mail
    end

    #Takes a +Receipt+ or an +Array+ of them and returns +true+ if the delivery was
    #successful or +false+ if some error raised
    def successful_delivery?(receipts)
      case receipts
      when MessageCenter::Receipt
        receipts.valid?
      when Array
        receipts.all?(&:valid?)
      else
        false
      end
    end
  end

end
