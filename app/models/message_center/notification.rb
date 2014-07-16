class MessageCenter::Notification < ActiveRecord::Base
  self.table_name = :message_center_notifications

  include MessageCenter::NotificationCoreConcerns

end
