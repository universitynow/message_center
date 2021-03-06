require 'spec_helper'

describe MessageCenter::Mailbox, :type => :model do

  before do
    @entity1 = FactoryGirl.create(:user)
    @entity2 = FactoryGirl.create(:user)
    @receipt1 = MessageCenter::Service.send_message(@entity2, @entity1, "Body","Subject")
    @receipt2 = MessageCenter::Service.reply_to_all(@receipt1, @entity2, "Reply body 1")
    @receipt3 = MessageCenter::Service.reply_to_all(@receipt2, @entity1, "Reply body 2")
    @receipt4 = MessageCenter::Service.reply_to_all(@receipt3, @entity2, "Reply body 3")
    @message1 = @receipt1.notification
    @message4 = @receipt4.notification
    @conversation = @message1.conversation.reload
  end

  it "should return all conversations" do
    @conv2 = MessageCenter::Service.send_message(@entity2, @entity1, "Body","Subject").conversation
    @conv4 = MessageCenter::Service.send_message(@entity2, @entity1, "Body","Subject").conversation
    @conv3 = MessageCenter::Service.send_message(@entity1, @entity2, "Body","Subject").conversation

    assert @entity1.mailbox.conversations

    expect(@entity1.mailbox.conversations.to_a.count).to eq(4)
    expect(@entity1.mailbox.conversations.to_a.count(@conversation)).to eq(1)
    expect(@entity1.mailbox.conversations.to_a.count(@conv2)).to eq(1)
    expect(@entity1.mailbox.conversations.to_a.count(@conv3)).to eq(1)
    expect(@entity1.mailbox.conversations.to_a.count(@conv4)).to eq(1)
  end

  it "should return all mail" do
    entity1_mailbox_receipts = @entity1.mailbox.receipts.order(:created_at => :desc,:id => :desc)
    entity2_mailbox_receipts = @entity2.mailbox.receipts.order(:created_at => :desc,:id => :desc)
    entity1_receipts_by_conversation = MessageCenter::Receipt.recipient(@entity1).conversation(@conversation).order(:created_at => :desc,:id => :desc)
    entity2_receipts_by_conversation = MessageCenter::Receipt.recipient(@entity2).conversation(@conversation).order(:created_at => :desc,:id => :desc)
    assert entity1_mailbox_receipts
    expect(entity1_mailbox_receipts.count).to eq(4)
    expect(entity1_mailbox_receipts[0]).to eq(entity1_receipts_by_conversation[0])
    expect(entity1_mailbox_receipts[1]).to eq(entity1_receipts_by_conversation[1])
    expect(entity1_mailbox_receipts[2]).to eq(entity1_receipts_by_conversation[2])
    expect(entity1_mailbox_receipts[3]).to eq(entity1_receipts_by_conversation[3])

    assert entity2_mailbox_receipts
    expect(entity2_mailbox_receipts.count).to eq(4)
    expect(entity2_mailbox_receipts[0]).to eq(entity2_receipts_by_conversation[0])
    expect(entity2_mailbox_receipts[1]).to eq(entity2_receipts_by_conversation[1])
    expect(entity2_mailbox_receipts[2]).to eq(entity2_receipts_by_conversation[2])
    expect(entity2_mailbox_receipts[3]).to eq(entity2_receipts_by_conversation[3])
  end

  it "should return sentbox" do
    assert @entity1.mailbox.receipts.inbox
    expect(@entity1.mailbox.receipts.sentbox.count).to eq(2)
    expect(@entity1.mailbox.receipts.sentbox[0]).to eq(@receipt3)
    expect(@entity1.mailbox.receipts.sentbox[1]).to eq(@receipt1)

    assert @entity2.mailbox.receipts.inbox
    expect(@entity2.mailbox.receipts.sentbox.count).to eq(2)
    expect(@entity2.mailbox.receipts.sentbox[0]).to eq(@receipt4)
    expect(@entity2.mailbox.receipts.sentbox[1]).to eq(@receipt2)
  end

  it "should return inbox" do
    assert @entity1.mailbox.receipts.inbox
    expect(@entity1.mailbox.receipts.inbox.count).to eq(2)
    expect(@entity1.mailbox.receipts.inbox[0]).to eq(MessageCenter::Receipt.recipient(@entity1).inbox.conversation(@conversation)[0])
    expect(@entity1.mailbox.receipts.inbox[1]).to eq(MessageCenter::Receipt.recipient(@entity1).inbox.conversation(@conversation)[1])

    assert @entity2.mailbox.receipts.inbox
    expect(@entity2.mailbox.receipts.inbox.count).to eq(2)
    expect(@entity2.mailbox.receipts.inbox[0]).to eq(MessageCenter::Receipt.recipient(@entity2).inbox.conversation(@conversation)[0])
    expect(@entity2.mailbox.receipts.inbox[1]).to eq(MessageCenter::Receipt.recipient(@entity2).inbox.conversation(@conversation)[1])
  end

  it "should understand the read option" do
    expect(@entity1.mailbox.inbox({:read => false}).count).not_to eq(0)
    @conversation.mark_as_read(@entity1)
    expect(@entity1.mailbox.inbox({:read => false}).count).to eq(0)
  end

  it "should return trashed mails" do
    @entity1.mailbox.receipts.move_to_trash

    entity1_trash_receipts = @entity1.mailbox.receipts.trash.order(:created_at => :desc,:id => :desc)
    entity1_receipts_by_conversation = MessageCenter::Receipt.recipient(@entity1).conversation(@conversation).order(:created_at => :desc,:id => :desc)

    assert entity1_trash_receipts
    expect(entity1_trash_receipts.count).to eq(4)
    expect(entity1_trash_receipts[0]).to eq(entity1_receipts_by_conversation[0])
    expect(entity1_trash_receipts[1]).to eq(entity1_receipts_by_conversation[1])
    expect(entity1_trash_receipts[2]).to eq(entity1_receipts_by_conversation[2])
    expect(entity1_trash_receipts[3]).to eq(entity1_receipts_by_conversation[3])

    assert @entity2.mailbox.receipts.trash
    expect(@entity2.mailbox.receipts.trash.count).to eq(0)
  end

  it "should delete trashed mails (TODO)" do
    @entity1.mailbox.receipts.move_to_trash
    #TODO
    #@entity1.mailbox.empty_trash

    assert @entity1.mailbox.receipts.trash
    #@entity1.mailbox.receipts.trash.count.should==0

    assert @entity2.mailbox.receipts
    expect(@entity2.mailbox.receipts.count).to eq(4)

    assert @entity2.mailbox.receipts.trash
    expect(@entity2.mailbox.receipts.trash.count).to eq(0)
  end

  it "should deleted messages are not shown in inbox" do
    assert @entity1.mailbox.receipts.inbox
    expect(@entity1.mailbox.inbox.count).to eq(1)
    expect(@entity1.mailbox.receipts.inbox[0]).to eq(MessageCenter::Receipt.recipient(@entity1).inbox.conversation(@conversation)[0])
    expect(@entity1.mailbox.receipts.inbox[1]).to eq(MessageCenter::Receipt.recipient(@entity1).inbox.conversation(@conversation)[1])

    assert @entity1.mailbox.receipts.inbox.mark_as_deleted
    @entity1.mailbox.inbox.reload
    expect(@entity1.mailbox.inbox.count).to eq(0)
  end

  it "should deleted messages are not shown in sentbox" do
    assert @entity1.mailbox.receipts.inbox
    expect(@entity1.mailbox.receipts.sentbox.count).to eq(2)
    expect(@entity1.mailbox.receipts.sentbox[0]).to eq(@receipt3)
    expect(@entity1.mailbox.receipts.sentbox[1]).to eq(@receipt1)

    assert @entity1.mailbox.receipts.sentbox.mark_as_deleted
    expect(@entity1.mailbox.sentbox.count).to eq(0)
  end

  it "should reply for deleted messages return to inbox" do
    assert @entity1.mailbox.receipts.inbox
    expect(@entity1.mailbox.inbox.count).to eq(1)
    expect(@entity1.mailbox.receipts.inbox[0]).to eq(MessageCenter::Receipt.recipient(@entity1).inbox.conversation(@conversation)[0])
    expect(@entity1.mailbox.receipts.inbox[1]).to eq(MessageCenter::Receipt.recipient(@entity1).inbox.conversation(@conversation)[1])

    assert @entity1.mailbox.receipts.inbox.mark_as_deleted
    expect(@entity1.mailbox.inbox.count).to eq(0)

    MessageCenter::Service.reply_to_all(@receipt1, @entity2, "Reply body 1")
    expect(@entity1.mailbox.inbox.count).to eq(1)

    MessageCenter::Service.reply_to_all(@receipt3, @entity2, "Reply body 3")
    expect(@entity1.mailbox.inbox.count).to eq(1)
  end

  context "STI models" do
    before do
      @sti_entity1 = FactoryGirl.create(:user)
      @sti_entity2 = FactoryGirl.create(:user)
      @sti_mail = MessageCenter::Service.send_message(@sti_entity2, @sti_entity1, "Body", "Subject")
    end

    it "should add one to senders sentbox" do
      expect(@sti_entity1.mailbox.sentbox.count).to eq(1)
      expect(@sti_entity1.mailbox.sentbox).to include(@sti_mail.conversation)
    end

    it "should add one to recievers inbox" do
      expect(@sti_entity2.mailbox.inbox.count).to eq(1)
      expect(@sti_entity2.mailbox.inbox).to include(@sti_mail.conversation)
    end
  end

end
