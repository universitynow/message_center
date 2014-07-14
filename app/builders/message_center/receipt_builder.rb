class MessageCenter::ReceiptBuilder < MessageCenter::BaseBuilder

  protected

  def klass
    MessageCenter::Receipt
  end

  def mailbox_type
    params.fetch(:mailbox_type, 'inbox')
  end

end
