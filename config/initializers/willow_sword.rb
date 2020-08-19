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
  config.default_user_email = 'oraadmin@bodleian.ox.ac.uk'
  # Use a workaround for incorrect in_progress SE calls
  config.in_progress_workaround = false
  # Should deposited zip files be unpacked? (required 'false' by Repotool2 behaviour)
  config.unpack_zip_files = true
  # Is there a maximum number of contributors in a Sword GET response?
  # Repotool2 times out after 100 seconds, so contributor lists > 300 have
  # proved problematic. 0 = no maximum
  # This value is used in the outbound MODS crosswalk only (/app/services/crosswalk_to_mods.rb)
  config.maximum_contributors_in_response = 0
  # Is there a maximum number of funders in a Sword GET response?
  # Repotool2 times out after 100 seconds, so funder lists > 100 have
  # proved problematic. 0 = no maximum
  # This value is used in the outbound MODS crosswalk only (/app/services/crosswalk_to_mods.rb)
  config.maximum_funders_in_response = 0
  # Used for where names appear in UPPER CASE
  config.titlecase_personal_names = false
  # Used for hard setting display names to Surname, Initials format
  config.display_name_as_family_name_initials = true
  # tmp directory location for request metadata and binary files
  config.tmp_directory_location = 'tmp/data'
end
