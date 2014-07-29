require 'spec_helper'

describe MessageCenter::MessageMailer, :type => :mailer do
  shared_examples 'message_mailer' do
    let(:sender) { FactoryGirl.create(:user) }
    let(:entity1) { FactoryGirl.create(:user) }
    let(:entity2) { FactoryGirl.create(:duck) }
    let(:entity3) { FactoryGirl.create(:cylon) }

    def sent_to?(entity)
      ActionMailer::Base.deliveries.any? do |email|
        email.to.first.to_s == entity.email
      end
    end

    describe "when sending new message" do
      before do
        @receipt1 = MessageCenter::Service.send_message([entity1, entity2, entity3], sender, "Body", "Subject")
      end

      it "should send emails when should_email? is true (1 out of 3)" do
        expect(ActionMailer::Base.deliveries).not_to be_empty
        expect(ActionMailer::Base.deliveries.size).to eq(1)
      end

      it "should send an email to user entity" do
        expect(sent_to?(entity1)).to be_truthy
      end

      it "shouldn't send an email to duck entity" do
        expect(sent_to?(entity2)).to be_falsey
      end

      it "shouldn't send an email to cylon entity" do
        expect(sent_to?(entity3)).to be_falsey
      end
    end

    describe "when replying" do
      before do
        @receipt1 = MessageCenter::Service.send_message([entity1, entity2, entity3], sender, "Body", "Subject")
        @receipt2 = MessageCenter::Service.reply_to_all(@receipt1, sender, "Body")
      end

      it "should send emails when should_email? is true (1 out of 3)" do
        expect(ActionMailer::Base.deliveries).not_to be_empty
        expect(ActionMailer::Base.deliveries.size).to eq(2)
      end

      it "should send an email to user entity" do
        expect(sent_to?(entity1)).to be_truthy
      end

      it "shouldn't send an email to duck entity" do
        expect(sent_to?(entity2)).to be_falsey
      end

      it "shouldn't send an email to cylon entity" do
        expect(sent_to?(entity3)).to be_falsey
      end
    end
  end

  context "when mailer_wants_array is false" do
    it_behaves_like 'message_mailer'
  end

  context "mailer_wants_array is true" do
    class ArrayMailer < MessageCenter::MessageMailer
      default template_path: 'message_center/message_mailer'

      def new_message_email(message, receivers)
        receivers.each { |receiver| super(message, receiver) if receiver.message_center_email(message).present? }
      end

      def reply_message_email(message, receivers)
        receivers.each { |receiver| super(message, receiver) if receiver.message_center_email(message).present? }
      end
    end

    before :all do
      MessageCenter.mailer_wants_array = true
      MessageCenter.message_mailer = ArrayMailer
    end

    after :all do
      MessageCenter.mailer_wants_array = false
      MessageCenter.message_mailer = MessageCenter::MessageMailer
    end

    it_behaves_like 'message_mailer'
  end
end

def print_emails
  ActionMailer::Base.deliveries.each do |email|
    puts "----------------------------------------------------"
    puts email.to
    puts "---"
    puts email.from
    puts "---"
    puts email.subject
    puts "---"
    puts email.body
    puts "---"
    puts email.encoded
    puts "----------------------------------------------------"
  end
end
