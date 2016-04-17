module MessageCenter
  class MailDispatcher

    attr_reader :mailable, :recipients

    def initialize(mailable, recipients)
      @mailable, @recipients = mailable, Array.wrap(recipients)
    end

    def call
      return false unless MessageCenter.uses_emails
      if MessageCenter.mailer_wants_array
        send_email(filtered_recipients)
      else
        filtered_recipients.each do |recipient|
          email_to = recipient.send(MessageCenter.email_method, mailable)
          send_email(recipient) if email_to.present?
        end
      end
    end

    private

    def mailer
      klass = mailable.class.name.demodulize
      method = "#{klass.downcase}_mailer".to_sym
      MessageCenter.send(method) || "#{mailable.class}Mailer".constantize
    end

    # recipients can be filtered on a conversation basis
    def filtered_recipients
      return recipients unless mailable.respond_to?(:conversation)

      recipients.each_with_object([]) do |recipient, array|
        array << recipient if mailable.conversation.has_subscriber?(recipient)
      end
    end

    def send_email(recipient)
      if MessageCenter.custom_deliver_proc
        MessageCenter.custom_deliver_proc.call(mailer, mailable, recipient)
      else
        mailer.send_email(mailable, recipient).deliver_now
      end
    end

  end
end
