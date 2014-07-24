class User < ActiveRecord::Base
  acts_as_messageable
  def message_center_email(object)
    return email
  end
end
