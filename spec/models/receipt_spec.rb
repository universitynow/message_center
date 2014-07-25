require 'spec_helper'

describe MessageCenter::Receipt, :type => :model do
  
  before do
    @entity1 = FactoryGirl.create(:user)
    @entity2 = FactoryGirl.create(:user)
    @mail1 = @entity1.send_message(@entity2,"Body","Subject")   
  end
  
  it "should belong to a message" do
    assert @mail1.notification
  end
  
  it "should belong to a conversation" do
    assert @mail1.conversation    
  end
  
  it "should be able to be marked as unread" do
    expect(@mail1.is_read).to eq(true)
    @mail1.mark_as_read(false)
    expect(@mail1.is_read).to eq(false)
  end
  
  it "should be able to be marked as read" do
    expect(@mail1.is_read).to eq(true)
    @mail1.mark_as_read(false)
    @mail1.mark_as_read
    expect(@mail1.is_read).to eq(true)    
  end

  it "should be able to be marked as deleted" do
    expect(@mail1.deleted).to eq(false)
    @mail1.mark_as_deleted
    expect(@mail1.deleted).to eq(true)
  end

  it "should be able to be marked as not deleted" do
    @mail1.deleted=true
    @mail1.mark_as_deleted(false)
    expect(@mail1.deleted).to eq(false)
  end

end
