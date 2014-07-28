module MessageCenter
  module Models
    module Messageable
      extend ActiveSupport::Concern

      included do
        has_many :messages, :class_name => 'MessageCenter::Message', :as => :sender
        if Rails::VERSION::MAJOR == 4
          has_many :receipts, -> { order(:created_at => :desc) }, :class_name => 'MessageCenter::Receipt', dependent: :destroy, foreign_key: 'receiver_id'
        else
          # Rails 3 does it this way
          has_many :receipts, :order => 'created_at DESC',    :class_name => 'MessageCenter::Receipt', :dependent => :destroy, :foreign_key => 'receiver_id'
        end
      end

      #Gets the mailbox of the messageable
      def mailbox
        @mailbox ||= MessageCenter::Mailbox.new(self)
      end

      #Sends a notification to the messageable
      def notify(subject,body,obj = nil,sanitize_text=true,notification_code=nil,send_mail=true)
        ActiveSupport::Deprecation.warn "User.notify() is deprecated and will be removed, use MessageCenter::Service.notify() instead.", caller
        MessageCenter::Service.notify(self, nil, subject, body, obj, sanitize_text, notification_code, send_mail)
      end

      #Sends a messages, starting a new conversation, with the messageable
      #as originator
      def send_message(recipients, msg_body, subject, sanitize_text=true, attachment=nil, message_timestamp = Time.now)
        ActiveSupport::Deprecation.warn "User.send_message() is deprecated and will be removed, use MessageCenter::Service.send_message() instead.", caller
        MessageCenter::Service.send_message(recipients, self, msg_body, subject, sanitize_text, attachment, message_timestamp)
      end

      #Basic reply method. USE NOT RECOMENDED.
      #Use reply_to_sender, reply_to_all and reply_to_conversation instead.
      def reply(conversation, recipients, reply_body, subject=nil, sanitize_text=true, attachment=nil)
        ActiveSupport::Deprecation.warn "User.reply() is deprecated and will be removed, use MessageCenter::Service.reply() instead.", caller
        MessageCenter::Service.reply(conversation, recipients, self, reply_body, subject=nil, sanitize_text=true, attachment=nil)
      end

      #Replies to the sender of the message in the conversation
      def reply_to_sender(receipt, reply_body, subject=nil, sanitize_text=true, attachment=nil)
        ActiveSupport::Deprecation.warn "User.reply_to_sender() is deprecated and will be removed, use MessageCenter::Service.reply_to_sender() instead.", caller
        MessageCenter::Service.reply(receipt.conversation, receipt.message.sender, self, reply_body, subject, sanitize_text, attachment)
      end

      #Replies to all the recipients of the message in the conversation
      def reply_to_all(receipt, reply_body, subject=nil, sanitize_text=true, attachment=nil)
        ActiveSupport::Deprecation.warn "User.reply_to_all() is deprecated and will be removed, use MessageCenter::Service.reply_to_all() instead.", caller
        MessageCenter::Service.reply(receipt.conversation, receipt.message.recipients, self, reply_body, subject, sanitize_text, attachment)
      end

      #Replies to all the recipients of the last message in the conversation and untrash any trashed message by messageable
      #if should_untrash is set to true (this is so by default)
      def reply_to_conversation(conversation, reply_body, subject=nil, should_untrash=true, sanitize_text=true, attachment=nil)
        ActiveSupport::Deprecation.warn "User.reply_to_conversation() is deprecated and will be removed, use MessageCenter::Service.reply_to_conversation() instead.", caller
        MessageCenter::Service.reply_to_conversation(conversation, self, reply_body, subject, should_untrash, sanitize_text, attachment)
      end

      def search_messages(query)
        @search = MessageCenter::Receipt.search do
          fulltext query
          with :receiver_id, self.id
        end

        @search.results.map { |r| r.conversation }.uniq
      end
    end
  end
end
