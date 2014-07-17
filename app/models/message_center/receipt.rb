class MessageCenter::Receipt < ActiveRecord::Base
  self.table_name = :message_center_receipts

  include MessageCenter::Concerns::Models::Receipt
end
