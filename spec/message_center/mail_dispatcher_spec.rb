require 'spec_helper'

describe MessageCenter::MailDispatcher do

  subject(:instance) { described_class.new(mailable, recipients) }

  let(:mailable)   { MessageCenter::Notification.new }
  let(:recipient1) { double 'recipient1', mailboxer_email: ''  }
  let(:recipient2) { double 'recipient2', mailboxer_email: 'foo@bar.com'  }
  let(:recipients) { [ recipient1, recipient2 ] }

  describe "call" do
    context "no emails" do
      before { MessageCenter.uses_emails = false }
      after  { MessageCenter.uses_emails = true }

      describe '#call' do
        subject { super().call }
        it { is_expected.to be_falsey }
      end
    end

    context "mailer wants array" do
      before { MessageCenter.mailer_wants_array = true  }
      after  { MessageCenter.mailer_wants_array = false }
      it 'sends collection' do
        expect(subject).to receive(:send_email).with(recipients)
        subject.call
      end
    end

    context "mailer doesnt want array" do
      it 'sends collection' do
        expect(subject).not_to receive(:send_email).with(recipient1) #email is blank
        expect(subject).to receive(:send_email).with(recipient2)
        subject.call
      end
    end
  end

  describe "send_email" do

    let(:mailer) { double 'mailer' }

    before(:each) do
      allow(subject).to receive(:mailer).and_return mailer
    end

    context "with custom_deliver_proc" do
      let(:my_proc) { double 'proc' }

      before { MessageCenter.custom_deliver_proc = my_proc }
      after  { MessageCenter.custom_deliver_proc = nil     }
      it "triggers proc" do
        expect(my_proc).to receive(:call).with(mailer, mailable, recipient1)
        subject.send :send_email, recipient1
      end
    end

    context "without custom_deliver_proc" do
      let(:email) { double :email }

      it "triggers standard deliver chain" do
        expect(mailer).to receive(:send_email).with(mailable, recipient1).and_return email
        expect(email).to receive :deliver

        subject.send :send_email, recipient1
      end
    end
  end

  describe "mailer" do
    let(:recipients) { [] }

    context "mailable is a Message" do
      let(:mailable) { MessageCenter::Notification.new }

      describe '#mailer' do
        subject { super().send(:mailer) }
        it { is_expected.to be MessageCenter::NotificationMailer }
      end

      context "with custom mailer" do
        before { MessageCenter.notification_mailer = 'foo' }
        after  { MessageCenter.notification_mailer = nil   }

        describe '#mailer' do
          subject { super().send(:mailer) }
          it { is_expected.to eq 'foo' }
        end
      end
    end

    context "mailable is a Notification" do
      let(:mailable) { MessageCenter::Message.new }

      describe '#mailer' do
        subject { super().send(:mailer) }
        it { is_expected.to be MessageCenter::MessageMailer }
      end

      context "with custom mailer" do
        before { MessageCenter.message_mailer = 'foo' }
        after  { MessageCenter.message_mailer = nil   }

        describe '#mailer' do
          subject { super().send(:mailer) }
          it { is_expected.to eq 'foo' }
        end
      end
    end
  end

  describe "filtered_recipients" do
    context "responds to conversation" do
      let(:conversation) { double 'conversation' }
      let(:mailable)     { double 'mailable', :conversation => conversation }
      before(:each) do
        expect(conversation).to receive(:has_subscriber?).with(recipient1).and_return false
        expect(conversation).to receive(:has_subscriber?).with(recipient2).and_return true
      end

      describe '#filtered_recipients' do
        subject { super().send(:filtered_recipients) }
        it { is_expected.to eq [recipient2] }
      end
    end

    context 'doesnt respond to conversation' do
      let(:mailable) { double 'mailable' }

      describe '#filtered_recipients' do
        subject { super().send(:filtered_recipients) }
        it { is_expected.to eq recipients }
      end
    end
  end
end
