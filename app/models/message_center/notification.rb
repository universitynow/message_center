class MessageCenter::Notification < ActiveRecord::Base
  self.table_name = :message_center_notifications

  include MessageCenter::Concerns::Models::Notification

end
