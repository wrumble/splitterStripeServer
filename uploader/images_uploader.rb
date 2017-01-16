require 'carrierwave/datamapper'
require 'carrierwave'

class ImagesUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick
  storage :file

  def filename
    "success.png"
  end
end
