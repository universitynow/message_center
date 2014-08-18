begin
  require 'carrierwave'
rescue LoadError
end
begin
  require 'sunspot_rails'
rescue LoadError
end

module MessageCenter
  class Engine < Rails::Engine
    isolate_namespace MessageCenter

    initializer 'message_center.default_callbacks' do
      if MessageCenter.use_mail_dispatcher && MessageCenter.uses_emails
        MessageCenter::Service.after_notify :call_mail_dispatcher
        MessageCenter::Service.after_send_message :call_mail_dispatcher
        MessageCenter::Service.after_reply :call_mail_dispatcher
      end
    end

  end
end
