WillowSword.setup do |config|
  # The title used by the sword server, in the service document
  config.title = 'Hyrax Sword V2 server'
  # If you do not want to use collections in Sword, it will use this as a default collection
  config.default_collection = {id: 'default', title: ['Default collection']}
  # The name of the model for retreiving collections (based on Hyrax integration)
  config.collection_models = ['Collection']
  # The work models supported by Sword (based on Hyrax integration)
  config.work_models = ['Work']
  # The fileset model supported by Sword (based on Hyrax integration)
  config.file_set_models = ['FileSet']
  # Remove all parameters that are not part of the model's permitted attributes
  config.allow_only_permitted_attributes = true
  # Default visibility for works
  config.default_visibility = 'open'
  # XML crosswalk for creating a work
  config.xw_from_xml_for_work = WillowSword::CrosswalkFromMets
  # XML crosswalk for creating a fileset
  config.xw_from_xml_for_fileset = WillowSword::CrosswalkFromOra
  # XML crosswalk when requesting a work
  config.xw_to_xml_for_work = WillowSword::CrosswalkToMets
  # XML crosswalk when requesting a fileet
  config.xw_to_xml_for_fileset = WillowSword::CrosswalkToOra
  # Authorize Sword requests using Api-key header
  config.authorize_request = false
  # Set new filesets to check_back by default
  config.check_back_by_default = true
  # Set default embargo end date for binary files if none is specified
  config.default_embargo_end_date = '9999-12-31'
  # Set the default user email address of the default user
  config.default_user_email = 'ora.system@bodleian.ox.ac.uk'
end
