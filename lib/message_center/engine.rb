begin
  require 'carrierwave'
rescue LoadError
end
begin
  require 'sunspot_rails'
rescue LoadError
end

module MessageCenter
  class Engine < Rails::Engine
    isolate_namespace MessageCenter
  end
end
