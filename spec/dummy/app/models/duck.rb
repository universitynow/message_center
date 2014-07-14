class Duck < ActiveRecord::Base
  acts_as_messageable
  def mailboxer_email(object)
    case object
    when MessageCenter::Message
      return nil
    when MessageCenter::Notification
      return email
    end
  end
end
