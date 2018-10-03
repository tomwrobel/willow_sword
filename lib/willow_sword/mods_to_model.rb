module WillowSword
  module ModsToModel

    def assign_mods_to_model
      # abstract
      if @metadata.fetch('abstract', []).any?
        @mapped_metadata['abstract'] = Array(@metadata['abstract']).first
      end
      # access_consition
      if @metadata.fetch('access_condition', []).any?
        parent = 'license_and_rights_information'
        assign_nested_term(parent, 'licence', @metadata['access_condition'])
      end
      # etd_extension
      if @metadata.fetch('etd', []).any?
        parent = 'bibliographic_information'
        assign_nested_hash(parent, @metadata.fetch['etd'].first)
      end
      # genre
      # identfier
      if @metadata.fetch('identifiers', []).any?
        assign_identifier
      end
      # Language
      if @metadata.fetch('language', []).any?
        @mapped_metadata['language'] = Array(@metadata['language']).first
      end
      # names
      if @metadata.fetch('names', []).any?
        assign_name
      end
      # notes
      if @metadata.fetch('notes', []).any?
        assign_nested_term('admin_information', 'notes', @metadata['notes'])
      end
      # origin info - copyright date
      if @metadata.fetch('copyrightDate', []).any?
        parent = 'license_and_rights_information'
        assign_nested_term(parent, 'copyright_date', @metadata['copyrightDate'])
      end
      # origin info - date captured
      if @metadata.fetch('dateCaptured', []).any?
        parent = 'bibliographic_information'
        assign_nested_term(parent, 'date_of_data_collection', @metadata['dateCaptured'])
      end
      # origin info - date issued
      if @metadata.fetch('dateIssued', []).any?
        assign_nested_term('publishers', 'publication_date', @metadata['dateIssued'])
      end
      # origin info - edition
      if @metadata.fetch('edition', []).any?
        assign_nested_term('publishers', 'edition', @metadata['edition'])
      end
      # origin info - place
      if @metadata.fetch('place', []).any?
        assign_nested_term('publishers', 'place_of_publication', @metadata['place'])
      end
      # origin info - publisher
      if @metadata.fetch('publisher', []).any?
        assign_nested_term('publishers', 'publisher_name', @metadata['publisher'])
      end
      # physical description - form
      if @metadata.fetch('form', []).any?
        assign_physical_desc
      end
      # physical description - extent
      if @metadata.fetch('extent', nil)
        assign_nested_term('files_information', 'extent', @metadata['extent'])
      end
      # record_info - recordContentSource
      if @metadata.fetch('record_info', []).any?
        assign_record_content_source
      end
      # related item
      @metadata.fetch('related_items', []).each do |ri|
        if ri.any? and ri.fetch('related_item_title', []).any?
          assign_nested_hash('related_items', ri, merge=false)
        end
      end
      # subject - genre
      if @metadata.fetch('genre', []).any?
        @mapped_metadata['keyword'] = Array(@metadata['genre'])
      end
      # subject - topic
      if @metadata.fetch('topic', []).any?
        @mapped_metadata['subject'] = Array(@metadata['topic'])
      end
      # subtitle
      if @metadata.fetch('subtitle', []).any?
        @mapped_metadata['subtitle'] = Array(@metadata['subtitle']).first
      end
      # title
      if @metadata.fetch('title', []).any?
        @mapped_metadata['title'] = Array(@metadata['title'])
      end
      # type_of_resource
      if @metadata.fetch('type_of_resource', []).any?
        parent = 'item_description_and_embargo_information'
        assign_nested_term(parent, 'type_of_resource', @metadata['type_of_resource'])
        assign_model(@metadata['type_of_resource'])
      end
    end

    private

    def assign_nested_term(parent, term, value)
      @mapped_metadata["#{parent}_attributes"] ||= []
      vals = @mapped_metadata["#{parent}_attributes"].first
      vals ||= {}
      vals[term] = Array(vals[term]) + Array(value)
      unless term == 'role'
        # All vals except role are singular
        vals[term] = Array(value).first
      end
      @mapped_metadata["#{parent}_attributes"] = [vals]
    end

    def assign_nested_hash(parent, values, merge=true)
      @mapped_metadata["#{parent}_attributes"] ||= []
      # All vals except role are singular
      values.each do |k, v|
        values[k] = Array(v)
        unless k == 'role'
          values[k] = Array(v).first
        end
      end
      values.delete_if {|k, v| v.blank?}
      if merge
        vals = @mapped_metadata["#{parent}_attributes"].first
        vals ||= {}
        vals.merge!(values)
        @mapped_metadata["#{parent}_attributes"] = [vals]
      else
        @mapped_metadata["#{parent}_attributes"] << values
      end
    end

    def assign_model(typ)
      typ_downcased = Array(typ).map { |t| t.gsub('_', ' ').gsub('-', ' ').downcase }
      # typ.any?{ |s| s.casecmp('thesis')==0 }
      if typ_downcased.include? ('journal article')
        @model = 'JournalArticle'
      elsif typ_downcased.include? ('thesis')
        @model = 'Thesis'
      else
        @model = 'Work'
      end
    end

    def assign_identifier
      ids = Marshal.load(Marshal.dump(@metadata.fetch('identifiers', []).first))
      return unless ids.any?
      ids['source_identifiers'] = ids.fetch('source_identifiers', []) +
                                  ids.fetch('local', []) +
                                  ids.fetch('localidentifier', [])
      ids['isbn_10'] = []
      ids['isbn_13'] = []
      ids.fetch('isbn', []).each do |isbn|
        isbn_length = isbn.gsub('-', '').gsub(' ', '')
        if isbn_length == 10
          ids['isbn_10'] << isbn
        else
          ids['isbn_13'] << isbn
        end
      end
      pubs_id = []
      ids.each do |key, vals|
        if key.include?('pub')
          vals.each do |val|
            unless val.include? ':'
              pubs_id << "pubs:#{val}"
            else
              pubs_id << val
            end
          end
        end
      end
      ids['pubs_id'] = pubs_id
      # @mapped_metadata['identifiers'] = [ids]
      # get publisher identifiers
      pub_attrs = {}
      id_keys = {
        'doi' => 'doi',
        'publisher_name' => 'publisher',
        'article_number' => 'article_number',
        'issn' => 'issn',
        'isbn_10' => 'isbn10',
        'isbn_13' => 'isbn13'
      }
      id_keys.each do |model_key, data_key|
        pub_attrs[model_key] = ids.fetch(data_key.to_s, nil)
      end
      pub_attrs.delete_if { |k, v| v.blank? }
      assign_nested_hash('publishers', pub_attrs) if pub_attrs.any?
      # get admin identifiers
      admin_attrs = {}
      admin_attrs['identifier_at_source'] = ids.fetch('source_identifiers', []) +
                                            ids.fetch('pubs_id', [])
      admin_attrs.delete_if { |k, v| v.blank? }
      assign_nested_hash('admin_information', admin_attrs) if admin_attrs.any?
    end

    def assign_name
      # map to creators_and_contributors
      # name
      #   display name => creator_name. If empty add firt + last
      # affiliation
      #   if type is institution division department sub_department research_group college map it
      #   otherwise map it to institution
      # identifier
      #   if orcid map it to creator_identifier. creator_identifier_scheme - Orcid
      #   all other id, map it to institutional_id
      aff_keys = %w(institution division department sub_department research_group college)
      id_keys = %w(orcid institutional_id)
      @metadata['names'].each do |name_hash|
        mapped_name = {}
        if name_hash.fetch('display_form', []).any?
          mapped_name['creator_name'] = Array(name_hash.fetch('display_form'))
        else
          # If display_form is empty add given + family
          family = Array(name_hash.dig('name_parts', 'family'))
          given = Array(name_hash.dig('name_parts', 'given'))
          display_form = (given + family).join(' ')
          if display_form.strip
            mapped_name['creator_name'] = [display_form.strip]
          end
        end
        name_hash.fetch('affiliation', []).each do |key, val|
          if aff_keys.include?(key.downcase)
            mapped_name[key.downcase] = mapped_name.fetch(key.downcase, [])
            mapped_name[key.downcase] += Array(val)
          else
            mapped_name['institution'] = mapped_name.fetch('institution', [])
            mapped_name['institution'] += Array(val)
          end
        end
        name_hash.fetch('identifiers', []).each do |key, val|
          if id_keys.include?(key.downcase)
            mapped_name[key.downcase] = mapped_name.fetch(key.downcase, [])
            mapped_name[key.downcase] += Array(val)
          else
            mapped_name['institutional_id'] = mapped_name.fetch('institutional_id', [])
            mapped_name['institutional_id'] += Array(val)
          end
        end
        if name_hash.fetch('role', []).any?
          mapped_name['role'] = Array(name_hash.fetch('role'))
        end
        assign_nested_hash('creators_and_contributors', mapped_name, merge=false)
      end
    end

    def assign_physical_desc
      vals = @metadata['form'].first
      if vals.fetch('peerReviewed', []).any?
        @mapped_metadata['peer_review_status'] = Array(vals['peerReviewed'])
      end
      if vals.fetch('status', []).any?
        @mapped_metadata['publication_status'] = Array(vals['status'])
      end
      if vals.fetch('version', []).any?
        parent = 'files_information'
        assign_nested_term(parent, 'version', vals['version'])
      end
    end

    def assign_record_content_source
      sources = []
      @metadata['record_info'].each do |ri|
        sources << ri['recordContentSource'] if ri.fetch('recordContentSource', []).any?
      end
      assign_nested_term('admin_information', 'source', sources)
    end
  end
end
