module MessageCenter
  module Service

    # Sends a notification to the recipients
    # options can include:
    #   :sanitize_text - boolean
    #   :send_mail - boolean
    def self.notify(recipients, sender, subject, body, attributes={}, options={})
      sanitize_text = options.delete(:sanitize_text) != false
      send_mail = options.delete(:send_mail) != false

      notification = MessageCenter::Notification.create!(attributes) do |item|
        item.sender = sender
        item.recipients = Array.wrap(recipients)
        item.subject = subject
        item.body = body
      end

      # TODO: change return value to be the notification
      # TODO: pass recipients to deliver directly
      notification.deliver(sanitize_text, send_mail)
    end

    # Sends a messages, starting a new conversation, with the recipients
    # TODO: reverse subject, body to match notify or vice-versa
    def self.send_message(recipients, sender, msg_body, subject, sanitize_text=true, attachment=nil, message_timestamp = Time.now)
      attributes = {
        :attachment   => attachment,
        :created_at   => message_timestamp,
        :updated_at   => message_timestamp
      }
      options = {
        :sanitize_text => sanitize_text
      }
      new_send_message(recipients, sender, subject, msg_body, attributes, options)
    end

    # New signature for send_message - need to update specs to call this
    def self.new_send_message(recipients, sender, subject, body, attributes={}, options={})
      conversation = MessageCenter::Conversation.create!(
          :subject    => subject,
          :created_at => attributes[:created_at],
          :updated_at => attributes[:updated_at]
      )

      message = MessageCenter::Message.create!(attributes) do |item|
        item.sender = sender
        item.conversation = conversation
        item.recipients = Array.wrap(recipients)
        item.subject = subject
        item.body = body
      end

      sanitize_text = options.delete(:sanitize_text) != false
      message.deliver(false, sanitize_text)

    end

    #Basic reply method. USE NOT RECOMENDED.
    #Use reply_to_sender, reply_to_all and reply_to_conversation instead.
    def self.reply(conversation, recipients, sender, body, subject=nil, sanitize_text=true, attachment=nil)
      attributes = {
        :attachment => attachment
      }
      attributes[:subject]=subject if subject.present?
      options = {
        :sanitize_text => sanitize_text
      }
      new_reply(conversation, recipients, sender, body, attributes, options)
    end

    def self.new_reply(conversation, recipients, sender, body, attributes={}, options={})
      subject = attributes.delete(:subject) || conversation.subject
      response = MessageCenter::Message.create!(attributes) do |item|
        item.conversation = conversation
        item.sender = sender
        item.recipients = Array.wrap(recipients)
        item.subject = subject
        item.body = body
      end

      response.recipients.delete(sender)
      sanitize_text = options.delete(:sanitize_text) != false
      response.deliver(true, sanitize_text)
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
