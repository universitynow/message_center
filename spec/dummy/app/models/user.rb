class User < ActiveRecord::Base
  include MessageCenter::Models::Messageable
  def message_center_email(object)
    return email
  end
end
