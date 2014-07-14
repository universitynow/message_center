# Database foreign keys
require 'foreigner'
require 'carrierwave'
begin
  require 'sunspot_rails'
rescue LoadError
end

module MessageCenter
  class Engine < Rails::Engine
    initializer "mailboxer.models.messageable" do
      ActiveSupport.on_load(:active_record) do
        extend MessageCenter::Models::Messageable::ActiveRecordExtension
      end
    end
  end
end
