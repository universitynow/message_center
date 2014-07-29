module MessageCenter
  module Service

    # Sends a notification to the recipients
    # options can include:
    #   :sanitize_text - boolean
    #   :send_mail - boolean
    def self.notify(recipients, sender, subject, body, attributes={}, options={})

      notification = MessageCenter::Notification.create!(attributes) do |item|
        item.sender = sender
        item.subject = subject
        item.body = body
        item.clean unless options[:sanitize_text] == false
      end

      # TODO: change return value to be the notification
      send_mail = options.delete(:send_mail) != false
      notification.deliver(recipients, send_mail)
    end

    # Sends a messages, starting a new conversation, with the recipients
    # TODO: reverse subject, body to match notify or vice-versa
    def self.send_message(recipients, sender, body, subject, attributes={}, options={})
      sanitize_text = options[:sanitize_text] != false
      conversation = MessageCenter::Conversation.create! do |convo|
        convo.subject = subject
        convo.created_at = attributes[:created_at]
        convo.updated_at = attributes[:updated_at]
        convo.clean if sanitize_text
      end

      message = MessageCenter::Message.create!(attributes) do |item|
        item.sender = sender
        item.conversation = conversation
        item.subject = subject
        item.body = body
        item.clean if sanitize_text
      end

      message.deliver(recipients)
    end

    #Basic reply method. USE NOT RECOMENDED.
    #Use reply_to_sender, reply_to_all and reply_to_conversation instead.
    def self.reply(conversation, recipients, sender, body, attributes={}, options={})
      subject = attributes.delete(:subject) || conversation.subject
      response = MessageCenter::Message.create!(attributes) do |item|
        item.conversation = conversation
        item.sender = sender
        item.subject = subject
        item.body = body
        item.clean unless options[:sanitize_text] == false
      end
      conversation.touch

      recipients = Array.wrap(recipients) - [sender]
      response.deliver(recipients)
    end

    #Replies to the sender of the message in the conversation
    def self.reply_to_sender(receipt, sender, body, attributes={}, options={})
      reply(receipt.conversation, receipt.message.sender, sender, body, attributes, options)
    end

    #Replies to all the recipients of the message in the conversation
    def self.reply_to_all(receipt, sender, body, attributes={}, options={})
      reply(receipt.conversation, receipt.message.receivers, sender, body, attributes, options)
    end

    #Replies to all the recipients of the last message in the conversation and untrash any trashed message by messageable
    #if should_untrash is set to true (this is so by default)
    def self.reply_to_conversation(conversation, sender, body, attributes={}, options={})
      #move conversation to inbox if it is currently in the trash and should_untrash parameter is true.
      if options[:should_untrash] != false && sender.mailbox.is_trashed?(conversation)
        sender.mailbox.receipts_for(conversation).move_to_trash(false)
        sender.mailbox.receipts_for(conversation).mark_as_deleted(false)
      end
      reply(conversation, conversation.last_message.recipients, sender, body, attributes, options)
    end

  end
end
