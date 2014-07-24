if defined?(CarrierWave)

class MessageCenter::AttachmentUploader < CarrierWave::Uploader::Base
  storage :file
end

end
