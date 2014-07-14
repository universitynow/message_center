class MessageCenter::Notification < ActiveRecord::Base
  self.table_name = :mailboxer_notifications

  include MessageCenter::NotificationCoreConcerns

end
