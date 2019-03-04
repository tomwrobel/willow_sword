module WillowSword
  module ModelToMods
    def assign_model_to_mods
      @mapped_metadata = {}
      # abstract
      @mapped_metadata['abstract'] = Array(@object[:abstract])
      # accessCondition
      if Array(@object[:license_and_rights_information]).any?
        @mapped_metadata['access_condition'] = Array(@object[:license_and_rights_information][0][:licence])
      end
      # identifiers
      @mapped_metadata['identifiers'] = {}
      # publisher ids - with publishers below
      # -- identifier from admin
      if Array(@object[:admin_information]).any?
        @mapped_metadata['identifiers']['source_identifiers'] = Array(@object[:admin_information][0][:identifier_at_source])
      end
      # Language
      @mapped_metadata['language'] = Array(@object[:language])
      # names
      @mapped_metadata['names'] = []
      Array(@object[:creators_and_contributors]).each do |creator|
        agent = {}
        # -- name
        agent['display_form'] = Array(creator[:creator_name]) if Array(creator[:creator_name]).any?
        # -- affiliation
        affiliation = {}
        aff_keys = [:institution, :division, :department, :sub_department, :research_group, :college]
        aff_keys.each do |aff_key|
          affiliation[aff_key.to_s] = Array(creator[aff_key]) if Array(creator[aff_key]).any?
        end
        agent['affiliation'] = affiliation if affiliation.any?
        # identifiers
        ids = {}
        id = Array(creator[:creator_identifier]).first
        id_key = Array(creator[:creator_identifier_scheme]).first
        if id and id_key
          ids[id_key] = Array(id)
        end
        agent['identifier'] = ids if ids.any?
        # role
        agent['role'] = Array(creator[:role]) if Array(creator[:role]).any?
        @mapped_metadata['names'] << agent if agent.any?
      end
      # notes
      if Array(@object[:admin_information]).any?
        @mapped_metadata['notes'] = Array(@object[:admin_information][0][:notes])
      end
      # origin info - copyright date
      if Array(@object[:license_and_rights_information]).any?
        @mapped_metadata['copyrightDate'] = Array(@object[:license_and_rights_information][0][:copyright_date])
      end
      if Array(@object[:bibliographic_information]).any?
        # origin info - date captured
        @mapped_metadata['dateCaptured'] = Array(@object[:bibliographic_information][0][:date_of_data_collection])
        # Origin Info and identifiers
        publishers = Array(@object.bibliographic_information[0][:publishers])
        if publishers.any?
          # origin info - date issued
          @mapped_metadata['dateIssued'] = Array(publishers[0][:publication_date])
          # origin info - edition
          @mapped_metadata['edition'] = Array(publishers[0][:edition])
          # origin info - place
          @mapped_metadata['place'] = Array(publishers[0][:place_of_publication])
          # origin info - publisher
          @mapped_metadata['publisher'] = Array(publishers[0][:publisher_name])
          # -- identfier from publishers
          id_keys = {
            doi:  'doi',
            publisher_name: 'publisher',
            article_number: 'article_number',
            issn: 'issn',
            isbn_10: 'isbn',
            isbn_13: 'isbn'
          }
          id_keys.each do |model_key, mods_key|
            if Array(publishers[0][model_key]).any?
              @mapped_metadata['identifiers'][mods_key] ||= []
              @mapped_metadata['identifiers'][mods_key] += Array(publishers[0][model_key])
            end
          end
        end
      end
      # physical description - form
      form = {}
      form['peerReviewed'] = Array(@object[:peer_review_status]) if Array(@object[:peer_review_status]).any?
      form['status'] = Array(@object[:publication_status]) if Array(@object[:publication_status]).any?
      if Array(@object[:files_information]).any?
        form['version'] = Array(@object[:files_information][0][:file_version]) if Array(@object[:files_information][0][:file_version]).any?
        @mapped_metadata['extent'] = Array(@object[:files_information][0][:extent])
      end
      @mapped_metadata['form'] = form if form.any?
      # record_info
      if Array(@object[:admin_information]).any?
        @mapped_metadata['record_info'] = {}
        @mapped_metadata['record_info']['recordContentSource'] = Array(@object[:admin_information][0][:source])
      end
      # related_items
      @mapped_metadata['related_items'] = []
      Array(@object[:related_items]).each do |ri|
        related_item = {}
        related_item['type'] = Array(ri[:related_item_type_of_relationship]) if Array(ri[:related_item_type_of_relationship]).any?
        related_item['title'] = Array(ri[:related_item_title]) if Array(ri[:related_item_title]).any?
        related_item['abstract'] = Array(ri[:related_item_abstract]) if Array(ri[:related_item_abstract]).any?
        related_item['identifier'] = Array(ri[:related_item_ID]) if Array(ri[:related_item_ID]).any?
         @mapped_metadata['related_items'] << related_item if related_item.any?
      end
      # subject - genre
      @mapped_metadata['genre'] = Array(@object[:keyword])
      # subject - topic
      @mapped_metadata['topic'] = Array(@object[:subject])
      # subtitle
      @mapped_metadata['subtitle'] = Array(@object[:subtitle])
      # title
      @mapped_metadata['title'] = Array(@object[:title])
      # type_of_resource
      parent = :item_description_and_embargo_information
      if Array(@object[parent]).any?
        @mapped_metadata['type_of_resource'] = Array(@object[parent][0][:type_of_resource])
      end
      @mapped_metadata
    end
  end
end
