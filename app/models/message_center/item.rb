class MessageCenter::Item < ActiveRecord::Base
  self.table_name = :message_center_items

  include MessageCenter::Concerns::Models::Item

end
