require 'spec_helper'

describe MessageCenter::Conversation, :type => :model do

  let!(:entity1)  { FactoryGirl.create(:user) }
  let!(:entity2)  { FactoryGirl.create(:user) }
  let!(:receipt1) { MessageCenter::Service.send_message(entity2, entity1, "Body","Subject") }
  let!(:receipt2) { MessageCenter::Service.reply_to_all(receipt1, entity2, "Reply body 1") }
  let!(:receipt3) { MessageCenter::Service.reply_to_all(receipt2, entity1, "Reply body 2") }
  let!(:receipt4) { MessageCenter::Service.reply_to_all(receipt3, entity2, "Reply body 3") }
  let!(:message1) { receipt1.notification }
  let!(:message4) { receipt4.notification }
  let!(:conversation) { message1.conversation.reload }

  it { is_expected.to validate_presence_of :subject }
  it { is_expected.to ensure_length_of(:subject).is_at_most(MessageCenter.subject_max_length) }

  it "should have proper original message" do
    expect(conversation.original_message).to eq(message1)
  end

  it "should have proper originator (first sender)" do
    expect(conversation.originator).to eq(entity1)
  end

  it "should have proper last message" do
    expect(conversation.last_message).to eq(message4)
  end

  it "should have proper last sender" do
    expect(conversation.last_sender).to eq(entity2)
  end

  it "should have all conversation users" do
    expect(conversation.recipients.count).to eq(2)
    expect(conversation.recipients.to_a.count(entity1)).to eq(1)
    expect(conversation.recipients.to_a.count(entity2)).to eq(1)
  end

  it "should be able to be marked as deleted" do
    conversation.move_to_trash(entity1)
    conversation.mark_as_deleted(entity1)
    expect(conversation).to be_is_deleted(entity1)
  end

  it "should be removed from the database once deleted by all participants" do
    conversation.mark_as_deleted(entity1)
    conversation.mark_as_deleted(entity2)
    expect(MessageCenter::Conversation.exists?(conversation.id)).to be_falsey
  end

  it "should be able to be marked as read" do
    conversation.mark_as_read(entity1)
    expect(conversation).to be_is_read(entity1)
  end

  it "should be able to be marked as unread" do
    conversation.mark_as_read(entity1)
    conversation.mark_as_read(entity1, false)
    expect(conversation).to be_is_unread(entity1)
  end

  it "should be able to add a new participant" do
    new_user = FactoryGirl.create(:user)
    conversation.add_participant(new_user)
    expect(conversation.participants.count).to eq(3)
    expect(conversation.participants).to include(new_user, entity1, entity2)
    expect(conversation.receipts_for(new_user).count).to eq(conversation.receipts_for(entity1).count)
  end

  it "should deliver messages to new participants" do
    new_user = FactoryGirl.create(:user)
    conversation.add_participant(new_user)
    expect{
      receipt5 = MessageCenter::Service.reply_to_all(receipt4, entity1, "Reply body 4")
    }.to change{ conversation.receipts_for(new_user).count }.by 1
  end

  describe "scopes" do
    let(:participant) { FactoryGirl.create(:user) }
    let!(:inbox_conversation) { MessageCenter::Service.send_message(participant, entity1, "Body", "Subject").notification.conversation }
    let!(:sentbox_conversation) { MessageCenter::Service.send_message(entity1, participant, "Body", "Subject").notification.conversation }


    describe ".participant" do
      it "finds conversations with receipts for participant" do
        expect(MessageCenter::Conversation.participant(participant)).to eq([sentbox_conversation, inbox_conversation])
      end
    end

    describe ".inbox" do
      it "finds inbox conversations with receipts for participant" do
        expect(MessageCenter::Conversation.inbox(participant)).to eq([inbox_conversation])
      end
    end

    describe ".sentbox" do
      it "finds sentbox conversations with receipts for participant" do
        expect(MessageCenter::Conversation.sentbox(participant)).to eq([sentbox_conversation])
      end
    end

    describe ".trash" do
      it "finds trash conversations with receipts for participant" do
        trashed_conversation = MessageCenter::Service.send_message(participant, entity1, "Body", "Subject").notification.conversation
        trashed_conversation.move_to_trash(participant)

        expect(MessageCenter::Conversation.trash(participant)).to eq([trashed_conversation])
      end
    end

    describe ".unread" do
      it "finds unread conversations with receipts for participant" do
        [sentbox_conversation, inbox_conversation].each {|c| c.mark_as_read(participant) }
        unread_conversation = MessageCenter::Service.send_message(participant, entity1, "Body", "Subject").notification.conversation

        expect(MessageCenter::Conversation.unread(participant)).to eq([unread_conversation])
      end
    end
  end

  describe "#is_completely_trashed?" do
    it "returns true if all receipts in conversation are trashed for participant" do
      conversation.move_to_trash(entity1)
      expect(conversation.is_completely_trashed?(entity1)).to be_truthy
    end
  end

  describe "#is_deleted?" do
    it "returns false if a recipient has not deleted the conversation" do
      expect(conversation.is_deleted?(entity1)).to be_falsey
    end

    it "returns true if a recipient has deleted the conversation" do
      conversation.mark_as_deleted(entity1)
      expect(conversation.is_deleted?(entity1)).to be_truthy
    end
  end

  describe "#is_orphaned?" do
    it "returns true if both participants have deleted the conversation" do
      conversation.mark_as_deleted(entity1)
      conversation.mark_as_deleted(entity2)
      expect(conversation.is_orphaned?).to be_truthy
    end

    it "returns false if one has not deleted the conversation" do
      conversation.mark_as_deleted(entity1)
      expect(conversation.is_orphaned?).to be_falsey
    end
  end


  describe "#opt_out" do
    context 'participant still opt in' do
      let(:opt_out) { conversation.opt_outs.first }

      it "creates an opt_out object" do
        expect{
          conversation.opt_out(entity1)
        }.to change{ conversation.opt_outs.count}.by 1
      end

      it "creates opt out object linked to the proper conversation and participant" do
        conversation.opt_out(entity1)
        expect(opt_out.conversation).to eq conversation
        expect(opt_out.unsubscriber).to eq entity1
      end
    end

    context 'participant already opted out' do
      before do
        conversation.opt_out(entity1)
      end
      it 'does nothing' do
        expect{
          conversation.opt_out(entity1)
        }.to_not change{ conversation.opt_outs.count}
      end
    end
  end

  describe "#opt_out" do
    context 'participant already opt in' do
      it "does nothing" do
        expect{
          conversation.opt_in(entity1)
        }.to_not change{ conversation.opt_outs.count }
      end
    end

    context 'participant opted out' do
      before do
        conversation.opt_out(entity1)
      end
      it 'destroys the opt out object' do
        expect{
          conversation.opt_in(entity1)
        }.to change{ conversation.opt_outs.count}.by -1
      end
    end
  end

  describe "#subscriber?" do
    let(:action) { conversation.has_subscriber?(entity1) }

    context 'participant opted in' do
      it "returns true" do
        expect(action).to be_truthy
      end
    end

    context 'participant opted out' do
      before do
        conversation.opt_out(entity1)
      end
      it 'returns false' do
        expect(action).to be_falsey
      end
    end
  end

end
