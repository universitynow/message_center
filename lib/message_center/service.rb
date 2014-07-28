module MessageCenter
  module Service

    #Sends a notification to the messageable
    def self.notify(recipients, sender, subject,body,obj = nil,sanitize_text=true,notification_code=nil,send_mail=true)
      notification = MessageCenter::Notification.new(
          :sender            => sender,
          :recipients        => Array.wrap(recipients),
          :subject           => subject,
          :body              => body,
          :notified_object   => obj,
          :notification_code => notification_code
      )

      notification.deliver sanitize_text, send_mail
    end

    #Sends a messages, starting a new conversation, with the messageable
    #as originator
    # TODO: reverse subject, body to match notify or vice-versa
    def self.send_message(recipients, sender, msg_body, subject, sanitize_text=true, attachment=nil, message_timestamp = Time.now)
      convo = MessageCenter::Conversation.create(
          :subject    => subject,
          :created_at => message_timestamp,
          :updated_at => message_timestamp
      )

      message = MessageCenter::Message.new(
          :sender       => sender,
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
    def self.reply(conversation, recipients, sender, reply_body, subject=nil, sanitize_text=true, attachment=nil)
      subject = subject || "#{conversation.subject}"
      response = MessageCenter::Message.new(
          :sender       => sender,
          :conversation => conversation,
          :recipients   => recipients,
          :body         => reply_body,
          :subject      => subject,
          :attachment   => attachment
      )

      response.recipients.delete(sender)
      response.deliver true, sanitize_text
    end

    #Replies to the sender of the message in the conversation
    def self.reply_to_sender(receipt, sender, reply_body, subject=nil, sanitize_text=true, attachment=nil)
      reply(receipt.conversation, receipt.message.sender, sender, reply_body, subject, sanitize_text, attachment)
    end

    #Replies to all the recipients of the message in the conversation
    def self.reply_to_all(receipt, sender, reply_body, subject=nil, sanitize_text=true, attachment=nil)
      reply(receipt.conversation, receipt.message.recipients, sender, reply_body, subject, sanitize_text, attachment)
    end

    #Replies to all the recipients of the last message in the conversation and untrash any trashed message by messageable
    #if should_untrash is set to true (this is so by default)
    def self.reply_to_conversation(conversation, sender, reply_body, subject=nil, should_untrash=true, sanitize_text=true, attachment=nil)
      #move conversation to inbox if it is currently in the trash and should_untrash parameter is true.
      if should_untrash && sender.mailbox.is_trashed?(conversation)
        sender.mailbox.receipts_for(conversation).move_to_trash(false)
        sender.mailbox.receipts_for(conversation).mark_as_deleted(false)
      end

      reply(conversation, conversation.last_message.recipients, sender, reply_body, subject, sanitize_text, attachment)
    end

  end
end
