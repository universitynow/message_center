MessageCenter.setup do |config|

  #Configures the Messagable class
  # config.messageable_class = 'User'

  #Configures if you application uses or not email sending for Notifications and Messages
  config.uses_emails = true

  #Configures whether mailer should be receive deliveries once or as a group
  # config.mailer_wants_array = false

  #Configures the default from for emails sent for Messages and Notifications
  config.default_from = 'no-reply@yourdomain.com'

  #Configures the methods needed by message_center
  config.email_method = :message_center_email
  config.name_method = :name

  #Configures custom implementation of notification and message mailers
  # config.notification_mailer = MessageCenter::NotificationMailer
  # config.message_mailer = MessageCenter::MessageMailerMailer

  #Configures if you use or not a search engine and which one you are using
  #Supported engines: [:solr,:sphinx]
  config.search_enabled = false
  config.search_engine = :solr

  #Configures maximum length of the message subject and body
  config.subject_max_length = 255
  config.body_max_length = 32000
end
