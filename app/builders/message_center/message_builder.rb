class MessageCenter::MessageBuilder < MessageCenter::BaseBuilder

  protected

  def klass
    MessageCenter::Message
  end

  def subject
    params[:subject] || default_subject
  end

  def default_subject
    "#{params[:conversation].subject}"
  end
end
