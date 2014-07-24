module MessageCenter
  module Models
    module Messageable
      extend ActiveSupport::Concern

      module ActiveRecordExtension
        #Converts the model into messageable allowing it to interchange messages and
        #receive notifications
        def acts_as_messageable
          include Messageable
        end
      end


      included do
        has_many :messages, :class_name => 'MessageCenter::Message', :as => :sender
        if Rails::VERSION::MAJOR == 4
          has_many :receipts, -> { order(:created_at => :desc) }, :class_name => 'MessageCenter::Receipt', dependent: :destroy, foreign_key: 'receiver_id'
        else
          # Rails 3 does it this way
          has_many :receipts, :order => 'created_at DESC',    :class_name => 'MessageCenter::Receipt', :dependent => :destroy, :foreign_key => 'receiver_id'
        end
      end

      unless defined?(MessageCenter.name_method)
        # Returning any kind of identification you want for the model
        define_method MessageCenter.name_method do
          begin
            super
          rescue NameError
            return "You should add method :#{MessageCenter.name_method} in your Messageable model"
          end
        end
      end

      unless defined?(MessageCenter.email_method)
        #Returning the email address of the model if an email should be sent for this object (Message or Notification).
        #If no mail has to be sent, return nil.
        define_method MessageCenter.email_method do |object|
          begin
            super
          rescue NameError
            return "You should add method :#{MessageCenter.email_method} in your Messageable model"
          end
        end
      end

      #Gets the mailbox of the messageable
      def mailbox
        @mailbox ||= MessageCenter::Mailbox.new(self)
      end

      #Sends a notification to the messageable
      def notify(subject,body,obj = nil,sanitize_text=true,notification_code=nil,send_mail=true)
        MessageCenter::Notification.notify_all([self],subject,body,obj,sanitize_text,notification_code,send_mail)
      end

      #Sends a messages, starting a new conversation, with the messageable
      #as originator
      def send_message(recipients, msg_body, subject, sanitize_text=true, attachment=nil, message_timestamp = Time.now)
        convo = MessageCenter::Conversation.create(
          :subject    => subject,
          :created_at => message_timestamp,
          :updated_at => message_timestamp
        )

        message = MessageCenter::Message.new(
          :sender       => self,
          :conversation => convo,
          :recipients   => recipients,
          :body         => msg_body,
          :subject      => subject,
          :attachment   => attachment,
          :created_at   => message_timestamp,
          :updated_at   => message_timestamp
        )

        message.deliver(false, sanitize_text)
      end

      #Basic reply method. USE NOT RECOMENDED.
      #Use reply_to_sender, reply_to_all and reply_to_conversation instead.
      def reply(conversation, recipients, reply_body, subject=nil, sanitize_text=true, attachment=nil)
        subject = subject || "#{conversation.subject}"
        response = MessageCenter::Message.new(
          :sender       => self,
          :conversation => conversation,
          :recipients   => recipients,
          :body         => reply_body,
          :subject      => subject,
          :attachment   => attachment
        )

        response.recipients.delete(self)
        response.deliver true, sanitize_text
      end

      #Replies to the sender of the message in the conversation
      def reply_to_sender(receipt, reply_body, subject=nil, sanitize_text=true, attachment=nil)
        reply(receipt.conversation, receipt.message.sender, reply_body, subject, sanitize_text, attachment)
      end

      #Replies to all the recipients of the message in the conversation
      def reply_to_all(receipt, reply_body, subject=nil, sanitize_text=true, attachment=nil)
        reply(receipt.conversation, receipt.message.recipients, reply_body, subject, sanitize_text, attachment)
      end

      #Replies to all the recipients of the last message in the conversation and untrash any trashed message by messageable
      #if should_untrash is set to true (this is so by default)
      def reply_to_conversation(conversation, reply_body, subject=nil, should_untrash=true, sanitize_text=true, attachment=nil)
        #move conversation to inbox if it is currently in the trash and should_untrash parameter is true.
        if should_untrash && mailbox.is_trashed?(conversation)
          mailbox.receipts_for(conversation).untrash
          mailbox.receipts_for(conversation).mark_as_not_deleted
        end

        reply(conversation, conversation.last_message.recipients, reply_body, subject, sanitize_text, attachment)
      end

      #Mark the object as read for messageable.
      #
      #Object can be:
      #* A Receipt
      #* A Message
      #* A Notification
      #* A Conversation
      #* An array with any of them
      def mark_as_read(obj, is_read=true)
        case obj
        when MessageCenter::Receipt
          obj.mark_as_read(is_read) if obj.receiver == self
        when Array
          obj.map{ |sub_obj| mark_as_read(sub_obj, is_read) }
        else
          obj.mark_as_read(self, is_read)
        end
      end

      #Mark the object as unread for messageable.
      def mark_as_unread(obj)
        mark_as_read(obj, false)
      end

      #Mark the object as deleted for messageable.
      #
      #Object can be:
      #* A Receipt
      #* A Notification
      #* A Message
      #* A Conversation
      #* An array with any of them
      def mark_as_deleted(obj)
        case obj
        when MessageCenter::Receipt
          return obj.mark_as_deleted if obj.receiver == self
        when Array
          obj.map{ |sub_obj| mark_as_deleted(sub_obj) }
        else
          obj.mark_as_deleted(self)
        end
      end

      #Mark the object as trashed for messageable.
      #
      #Object can be:
      #* A Receipt
      #* A Message
      #* A Notification
      #* A Conversation
      #* An array with any of them
      def trash(obj, trashed=true)
        case obj
        when MessageCenter::Receipt
          obj.move_to_trash(trashed) if obj.receiver == self
        when Array
          obj.map{ |sub_obj| trash(sub_obj, trashed) }
        else
          obj.move_to_trash(self, trashed)
        end
      end

      #Mark the object as not trashed for messageable.
      #
      #Object can be:
      #* A Receipt
      #* A Message
      #* A Notification
      #* A Conversation
      #* An array with any of them
      def untrash(obj)
        trash(obj, false)
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
