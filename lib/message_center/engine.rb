require 'carrierwave'
begin
  require 'sunspot_rails'
rescue LoadError
end

module MessageCenter
  class Engine < Rails::Engine
    isolate_namespace MessageCenter
    initializer "message_center.models.messageable" do
      ActiveSupport.on_load(:active_record) do
        extend MessageCenter::Models::Messageable::ActiveRecordExtension
      end
    end
  end
end
