require 'singleton'

module MessageCenter
  class Cleaner
    include Singleton
    include ActionView::Helpers::SanitizeHelper

  end
end
