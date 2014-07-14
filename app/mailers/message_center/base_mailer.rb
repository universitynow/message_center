class MessageCenter::BaseMailer < ActionMailer::Base
  default :from => MessageCenter.default_from

  private

  def set_subject(container)
    @subject  = container.subject.html_safe? ? container.subject : strip_tags(container.subject)
  end

  def strip_tags(text)
    ::MessageCenter::Cleaner.instance.strip_tags(text)
  end

end
