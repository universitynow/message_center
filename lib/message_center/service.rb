require 'hooks'

module MessageCenter
  class Service
    include Hooks

    define_hooks :after_notify, :after_send_message

    # Sends a notification to the recipients
    # options can include:
    #   :sanitize_text - boolean
    #   :send_mail - boolean
    def self.notify(recipients, sender, body, subject, attributes={}, options={})

      notification = MessageCenter::Notification.new(attributes.merge({:sender => sender,
                                                                       :subject => subject,
                                                                       :body => body}))
      notification.clean unless options[:sanitize_text] == false
      notification.save!

      notification.deliver(recipients)

      run_hook :after_notify, notification, recipients, options

      notification
    end

    # Sends a messages, starting a new conversation, with the recipients
    def self.send_message(recipients, sender, body, subject, attributes={}, options={})

      message = MessageCenter::Message.new(attributes.merge({:sender => sender,
                                                             :subject => subject,
                                                             :body => body}))

      message.clean if options[:sanitize_text] != false
      unless message.conversation
        message.conversation = message.build_conversation(:subject => message.subject,
                                                          :created_at => attributes[:created_at],
                                                          :updated_at => attributes[:updated_at])
      end

      message.save!

      sender_receipt = message.create_sender_receipt

      message.deliver(recipients)

      run_hook :after_send_message, message, recipients, options

      sender_receipt
    end

    #Basic reply method. USE NOT RECOMENDED.
    #Use reply_to_sender, reply_to_all and reply_to_conversation instead.
    def self.reply(conversation, recipients, sender, body, attributes={}, options={})
      subject = attributes.delete(:subject) || conversation.subject
      recipients = Array.wrap(recipients) - [sender]
      conversation.touch
      send_message(recipients, sender, body, subject, attributes.merge(:conversation => conversation), options)
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

    def self.call_mail_dispatcher(item, recipients, options)
      MessageCenter::MailDispatcher.new(item, recipients).call unless options[:send_mail] == false
    end

  end
end
