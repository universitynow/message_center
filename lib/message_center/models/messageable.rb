module MessageCenter
  module Models
    module Messageable
      extend ActiveSupport::Concern

      included do
        has_many :messages, :class_name => 'MessageCenter::Message', :as => :sender
        if Rails::VERSION::MAJOR == 4
          has_many :receipts, -> { order(:created_at => :desc) }, :class_name => 'MessageCenter::Receipt', dependent: :destroy, foreign_key: 'receiver_id'
        else
          # Rails 3 does it this way
          has_many :receipts, :order => 'created_at DESC',    :class_name => 'MessageCenter::Receipt', :dependent => :destroy, :foreign_key => 'receiver_id'
        end
      end

      #Gets the mailbox of the messageable
      def mailbox
        @mailbox ||= MessageCenter::Mailbox.new(self)
      end

      def search_messages(query)
        @search = MessageCenter::Receipt.search do
          fulltext query
          with :receiver_id, self.id
        end

        @search.results.map { |r| r.conversation }.uniq
      end
    end
  end
end
