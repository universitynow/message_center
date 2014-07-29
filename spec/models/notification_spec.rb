require 'spec_helper'

describe MessageCenter::Notification, :type => :model do

  before do
    @entity1 = FactoryGirl.create(:user)
    @entity2 = FactoryGirl.create(:user)
    @entity3 = FactoryGirl.create(:user)
  end

  it { is_expected.to validate_presence_of :subject }
  it { is_expected.to validate_presence_of :body }

  it { is_expected.to ensure_length_of(:subject).is_at_most(MessageCenter.subject_max_length) }
  it { is_expected.to ensure_length_of(:body).is_at_most(MessageCenter.body_max_length) }

  it "should notify one user" do
    MessageCenter::Service.notify(@entity1, nil, "Subject", "Body")

    #Check getting ALL receipts
    expect(@entity1.mailbox.receipts.size).to eq(1)
    receipt      = @entity1.mailbox.receipts.first
    notification = receipt.notification
    expect(notification.subject).to eq("Subject")
    expect(notification.body).to eq("Body")

    #Check getting NOTIFICATION receipts only
    expect(@entity1.mailbox.notifications.size).to eq(1)
    notification = @entity1.mailbox.notifications.first
    expect(notification.subject).to eq("Subject")
    expect(notification.body).to eq("Body")
  end

  it "should be unread by default" do
    MessageCenter::Service.notify(@entity1, nil, "Subject", "Body")
    expect(@entity1.mailbox.receipts.size).to eq(1)
    notification = @entity1.mailbox.receipts.first.notification
    expect(notification.receipt_for(@entity1).first.is_unread?).to be_truthy
  end

  it "should be able to marked as read" do
    MessageCenter::Service.notify(@entity1, nil, "Subject", "Body")
    expect(@entity1.mailbox.receipts.size).to eq(1)
    notification = @entity1.mailbox.receipts.first.notification
    notification.mark_as_read(@entity1)
    expect(notification.receipt_for(@entity1).first.is_read?).to be_truthy
  end

  it "should notify several users" do
    recipients = [@entity1,@entity2,@entity3]
    MessageCenter::Service.notify(recipients, nil, "Subject", "Body")
    #Check getting ALL receipts
    expect(@entity1.mailbox.receipts.size).to eq(1)
    receipt      = @entity1.mailbox.receipts.first
    notification = receipt.notification
    expect(notification.subject).to eq("Subject")
    expect(notification.body).to eq("Body")
    expect(@entity2.mailbox.receipts.size).to eq(1)
    receipt      = @entity2.mailbox.receipts.first
    notification = receipt.notification
    expect(notification.subject).to eq("Subject")
    expect(notification.body).to eq("Body")
    expect(@entity3.mailbox.receipts.size).to eq(1)
    receipt      = @entity3.mailbox.receipts.first
    notification = receipt.notification
    expect(notification.subject).to eq("Subject")
    expect(notification.body).to eq("Body")

    #Check getting NOTIFICATION receipts only
    expect(@entity1.mailbox.notifications.size).to eq(1)
    notification = @entity1.mailbox.notifications.first
    expect(notification.subject).to eq("Subject")
    expect(notification.body).to eq("Body")
    expect(@entity2.mailbox.notifications.size).to eq(1)
    notification = @entity2.mailbox.notifications.first
    expect(notification.subject).to eq("Subject")
    expect(notification.body).to eq("Body")
    expect(@entity3.mailbox.notifications.size).to eq(1)
    notification = @entity3.mailbox.notifications.first
    expect(notification.subject).to eq("Subject")
    expect(notification.body).to eq("Body")

  end

  it "should notify a single recipient" do
    MessageCenter::Service.notify(@entity1, nil, "Subject", "Body")

    #Check getting ALL receipts
    expect(@entity1.mailbox.receipts.size).to eq(1)
    receipt      = @entity1.mailbox.receipts.first
    notification = receipt.notification
    expect(notification.subject).to eq("Subject")
    expect(notification.body).to eq("Body")

    #Check getting NOTIFICATION receipts only
    expect(@entity1.mailbox.notifications.size).to eq(1)
    notification = @entity1.mailbox.notifications.first
    expect(notification.subject).to eq("Subject")
    expect(notification.body).to eq("Body")
  end

  describe "scopes" do
    let(:scope_user) { FactoryGirl.create(:user) }
    let!(:notification) { MessageCenter::Service.notify(scope_user, nil, "Subject", "Body") }

    describe ".unread" do
      it "finds unread notifications" do
        unread_notification = MessageCenter::Service.notify(scope_user, nil, "Subject", "Body")
        notification.mark_as_read(scope_user)
        expect(MessageCenter::Notification.unread.last).to eq(unread_notification)
      end
    end

    describe ".expired" do
      it "finds expired notifications" do
        notification.update_attributes(expires_at: 1.day.ago)
        expect(scope_user.mailbox.notifications.expired.count).to eq(1)
      end
    end

    describe ".unexpired" do
      it "finds unexpired notifications" do
        notification.update_attributes(expires_at: 1.day.from_now)
        expect(scope_user.mailbox.notifications.unexpired.count).to eq(1)
      end
    end
  end

  describe "#expire" do
    subject { described_class.new }

    describe "when the notification is already expired" do
      before do
        allow(subject).to receive_messages(:expired? => true)
      end
      it 'should not update the expires_at attribute' do
        expect(subject).not_to receive :expires_at=
        expect(subject).not_to receive :save
        subject.expire
      end
    end

    describe "when the notification is not expired" do
      let(:now) { Time.now }
      let(:one_second_ago) { now - 1.second }
      before do
        allow(Time).to receive_messages(:now => now)
        allow(subject).to receive_messages(:expired? => false)
      end
      it 'should update the expires_at attribute' do
        expect(subject).to receive(:expires_at=).with(one_second_ago)
        subject.expire
      end
      it 'should not save the record' do
        expect(subject).not_to receive :save
        subject.expire
      end
    end

  end

  describe "#expire!" do
    subject { described_class.new }

    describe "when the notification is already expired" do
      before do
        allow(subject).to receive_messages(:expired? => true)
      end
      it 'should not call expire' do
        expect(subject).not_to receive :expire
        expect(subject).not_to receive :save
        subject.expire!
      end
    end

    describe "when the notification is not expired" do
      let(:now) { Time.now }
      let(:one_second_ago) { now - 1.second }
      before do
        allow(Time).to receive_messages(:now => now)
        allow(subject).to receive_messages(:expired? => false)
      end
      it 'should call expire' do
        expect(subject).to receive(:expire)
        subject.expire!
      end
      it 'should save the record' do
        expect(subject).to receive :save
        subject.expire!
      end
    end

  end

  describe "#expired?" do
    subject { described_class.new }
    context "when the expiration date is in the past" do
      before { allow(subject).to receive_messages(:expires_at => Time.now - 1.second) }
      it 'should be expired' do
        expect(subject.expired?).to be_truthy
      end
    end

    context "when the expiration date is now" do
      before {
        time = Time.now
        allow(Time).to receive_messages(:now => time)
        allow(subject).to receive_messages(:expires_at => time)
      }

      it 'should not be expired' do
        expect(subject.expired?).to be_falsey
      end
    end

    context "when the expiration date is in the future" do
      before { allow(subject).to receive_messages(:expires_at => Time.now + 1.second) }
      it 'should not be expired' do
        expect(subject.expired?).to be_falsey
      end
    end

    context "when the expiration date is not set" do
      before {allow(subject).to receive_messages(:expires_at => nil)}
      it 'should not be expired' do
        expect(subject.expired?).to be_falsey
      end
    end

  end

end
