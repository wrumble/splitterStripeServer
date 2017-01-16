require_relative '../uploader/images_uploader.rb'
require 'data_mapper'
require 'carrierwave/datamapper'
require 'dm-postgres-adapter'

class Image
  include DataMapper::Resource

  property :id, Serial
  mount_uploader :file, ImagesUploader
end
