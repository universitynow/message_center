class Duck < User
  def mailboxer_email(object)
    case object
    when MessageCenter::Message
      return nil
    when MessageCenter::Notification
      return email
    end
  end
end
