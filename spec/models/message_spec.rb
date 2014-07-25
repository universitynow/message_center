require 'spec_helper'

describe MessageCenter::Message, :type => :model do
  
  before do
    @entity1 = FactoryGirl.create(:user)
    @entity2 = FactoryGirl.create(:user)
    @receipt1 = @entity1.send_message(@entity2,"Body","Subject")
    @receipt2 = @entity2.reply_to_all(@receipt1,"Reply body 1")
    @receipt3 = @entity1.reply_to_all(@receipt2,"Reply body 2")
    @receipt4 = @entity2.reply_to_all(@receipt3,"Reply body 3")
    @message1 = @receipt1.notification
    @message4 = @receipt4.notification
    @conversation = @message1.conversation
  end  
  
  it "should have right recipients" do
  	expect(@receipt1.notification.recipients.count).to eq(2)
  	expect(@receipt2.notification.recipients.count).to eq(2)
  	expect(@receipt3.notification.recipients.count).to eq(2)
  	expect(@receipt4.notification.recipients.count).to eq(2)      
  end

  it "should be able to be marked as deleted" do
    expect(@receipt1.deleted).to eq(false)
    @message1.mark_as_deleted @entity1
    expect(@message1.receipt_for(@entity1).first.deleted?).to eq(true)
  end
    
end
