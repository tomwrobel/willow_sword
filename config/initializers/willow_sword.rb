WillowSword.setup do |config|
  config.title = 'Hyrax Sword V2 server'
  config.default_collection = {id: 'default', title: ['Default collection']}
  config.collection_models = ['Collection']
  config.work_models = ['Work']
  config.file_set_models = ['FileSet']
end
