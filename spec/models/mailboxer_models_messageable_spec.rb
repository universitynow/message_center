require 'spec_helper'

describe "MessageCenter::Models::Messageable through User", :type => :model do

  before do
    @entity1 = FactoryGirl.create(:user)
    @entity2 = FactoryGirl.create(:user)
  end

  it "should have a mailbox" do
    assert @entity1.mailbox
  end

  it "should be able to send a message" do
    assert MessageCenter::Service.send_message(@entity2, @entity1, "Body","Subject")
  end

  it "should be able to reply to sender" do
    @receipt = MessageCenter::Service.send_message(@entity2, @entity1,"Body","Subject")
    assert MessageCenter::Service.reply_to_sender(@receipt, @entity2, "Reply body")
  end

  it "should be able to reply to all" do
    @receipt = MessageCenter::Service.send_message(@entity2, @entity1,"Body","Subject")
    assert MessageCenter::Service.reply_to_all(@receipt, @entity2, "Reply body")
  end

  it "should be able to read attachment" do
    skip 'attachments can not be tested without carrierwave' unless defined?(CarrierWave)
    @receipt = MessageCenter::Service.send_message(@entity2, @entity1, "Body", "Subject", nil, File.open('spec/testfile.txt'))
    @conversation = @receipt.conversation
    expect(@conversation.messages.first.attachment_identifier).to eq('testfile.txt')
  end

  it "should be the same message time as passed" do
    message_time = 5.days.ago
    receipt = MessageCenter::Service.send_message(@entity2, @entity1, "Body", "Subject", nil, nil, message_time)
    # We're going to compare the string representation, because ActiveSupport::TimeWithZone
    # has microsecond precision in ruby, but some databases don't support this level of precision.
    expected = message_time.utc.to_s
    expect(receipt.message.created_at.utc.to_s).to eq(expected)
    expect(receipt.message.updated_at.utc.to_s).to eq(expected)
    expect(receipt.message.conversation.created_at.utc.to_s).to eq(expected)
    expect(receipt.message.conversation.updated_at.utc.to_s).to eq(expected)
  end

end
