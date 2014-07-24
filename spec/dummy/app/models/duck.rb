class Duck < User
  def message_center_email(object)
    case object
    when MessageCenter::Message
      return nil
    when MessageCenter::Notification
      return email
    end
  end
end
