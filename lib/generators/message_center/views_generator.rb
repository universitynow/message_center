class MessageCenter::ViewsGenerator < Rails::Generators::Base
  source_root File.expand_path("../../../../app/views", __FILE__)

  desc "Copy MessageCenter views into your app"
  def copy_views
    directory('message_center/message_mailer', 'app/views/message_center/message_mailer')
    directory('message_center/notification_mailer', 'app/views/message_center/notification_mailer')
  end

end
