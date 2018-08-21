module WillowSword
  class ModsCrosswalk
    attr_reader :metadata, :model, :mods
    def initialize(src_file)
      @src_file = src_file
      @mods = nil
      @metadata = {}
    end

    def read_file
      return @metadata unless @src_file.present?
      return @metadata unless File.exist? @src_file
      f = File.open(@src_file) # { |conf| conf.noblanks }
      doc = Nokogiri::XML(f)
      if doc.root.name == 'modsCollection'
        @mods = doc.xpath('/mods:modsCollection/mods:mods')
      else
        @mods = doc.xpath('/mods:mods')
      end
    end

    def parse_mods
      get_abstract
      get_access_condition
      get_etd_extension
      get_genre
      get_identifier
      get_language
      get_name
      get_note
      get_origin_info
      get_physical_description
      get_extent
      get_record_info
      get_related_item
      get_subject_genre
      get_subject_topic
      get_title
      get_subtitle
    end

    def get_abstract
      # Map to abstract
      # get text with html tags
      @metadata['abstract'] = get_text_with_tags(@mods, 'mods:abstract')
    end

    def get_access_condition
      # Map to license_and_rights_information
      #   licence
      licence = get_text_with_tags(@mods, 'mods:accessCondition')
      parent = 'license_and_rights_information'
      assign_nested_term(parent, 'licence', licence)
    end

    def get_etd_extension
      # Map to bibliographic_information
      #   degree_name, degree_level, degree_institution
      etd = @mods.xpath('./etd:degree')
      return unless etd.present?
      vals = {}
      vals['degree_name'] = get_text(etd, 'etd:name')
      vals['degree_level'] = get_text(etd, 'etd:level')
      vals['degree_institution'] = get_text(etd, 'etd:institution')
      parent = 'bibliographic_information'
      assign_nested_hash(parent, vals)
    end

    def get_genre
      # Map to model
      typ = get_text(@mods, 'mods:genre')
      # Map to item_description_and_embargo_information
      #   type_of_resource
      parent = 'item_description_and_embargo_information'
      assign_nested_term(parent, 'type_of_resource', typ)
      assign_model(typ)
    end

    def get_identifier
      ids = get_value_by_type(@mods, 'mods:identifier', 'other')
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
      assign_identifier(ids)
    end

    def get_language
      @metadata['language'] = get_text(@mods, 'mods:language/mods:languageTerm')
    end

    def get_name
      names = []
      @mods.search('./mods:name').each do |nam|
        name_attrs = {}
        # name_part
        name_attrs['name_parts'] = get_value_by_type(nam, 'mods:namePart', 'name_part')
        # affiliation
        name_attrs['affiliation'] = get_value_by_type(nam, 'mods:affiliation', 'institution')
        # display form
        name_attrs['display_form'] = get_text(nam, 'mods:displayForm')
        # role
        name_attrs['role'] = get_text(nam, 'mods:role/mods:roleTerm')
        # extension
        name_attrs['identifiers'] = get_value_by_type(nam, 'mods:extension', 'identifier')
        names << name_attrs
      end
      assign_name(names)
    end

    def get_note
      # map notes to admin_information['notes']
      @mods.search('./mods:note').each do |note|
        typ = note.xpath('@type')
        typ = 'additionalinformation' if typ.blank?
        if typ.to_s == 'additionalinformation'
          @metadata['notes'] = @metadata.fetch('notes', [])
          @metadata['notes'] << note.text.strip
        else
          label = note.xpath('@displayLabel')
          if label == 'patent-status'
            @metadata[label] = @metadata.fetch(label, [])
            @metadata[label] << note.text.strip
          end
        end
      end
    end

    def get_origin_info
      @mods.search('./mods:originInfo').each do |origin|
        # TODO: Need to parse date text for uniformity
        # publication date
        #   map to publishers['publication_date']
        vals = get_text(origin, 'mods:dateIssued')
        parent = 'publishers'
        assign_nested_term(parent, 'publication_date', vals)  if vals.any?
        # copyright date
        #   map to license_and_rights_information['copyright_date']
        vals = get_text(origin, 'mods:copyrightDate')
        parent = 'license_and_rights_information'
        assign_nested_term(parent, 'copyright_date', vals)  if vals.any?
        # get date by type
        #   map dateOfAcceptance to publishers['acceptance_date']
        #   ignore other date types
        vals = get_value_by_type(origin, 'mods:dateOther', 'other_date')
        if vals.fetch('dateOfAcceptance', []).any?
          parent = 'publishers'
          assign_nested_term(parent, 'acceptance_date', vals['dateOfAcceptance'])
        end
      end
    end

    def get_physical_description
      # Map peer_review_status nd publication_status
      # version maps to files_information['version']
      # Ignore all others
      vals = get_value_by_type(@mods, "mods:physicalDescription/mods:form", 'other')
      if vals.fetch('peerReviewed', []).any?
        @metadata['peer_review_status'] = Array(vals['peerReviewed'])
      end
      if vals.fetch('status', []).any?
        @metadata['publication_status'] = Array(vals['status'])
      end
      if vals.fetch('version', []).any?
        # TODO: parse version to check if it is rioxx version.
        # if yes, save val with key rioxx_version
        parent = 'files_information'
        assign_nested_term(parent, 'version', vals['version'])
      end
    end

    def get_extent
      # maps to files_information['extent']
      @metadata['extent'] = get_text(@mods, 'mods:physicalDescription/mods:extent')
    end

    def get_record_info
      # maps to admin_information['source']
      val = get_text(@mods, 'mods:recordInfo/mods:recordContentSource')
      parent = 'admin_information'
      assign_nested_term(parent, 'source', val)
    end

    def get_related_item
      @mods.search('./mods:relatedItem').each do |ele|
        typ = ele.xpath('@type')
        # extract host or series values
        return unless ['host', 'series'].include?(typ.to_s)
        # map title to related_items['related_item_title']
        # Ignore all other fields
        val = {}
        titles = get_text(ele, 'mods:titleInfo/mods:title')
        val['title'] = titles if titles.any?
        ele.search('./mods:part/mods:detail').each do |ele2|
          typ2 = ele2.xpath('@type')
          typ2 = 'paper_number' if typ2.blank?
          if ele2.children.count > 0 and ele2.children.first.text
            val[typ2] = [ele2.children.first.text.strip]
          end
        end
        ele.search('./mods:part/mods:extent').each do |ele2|
          typ2 = ele2.xpath('@unit')
          if typ2 and ele2.children.count > 0 and ele2.children.first.text
            val[typ2.downcase] = [ele2.children.first.text.strip]
          end
        end
        if val.fetch('title', nil)
          parent = 'related_items'
          assign_nested_term(parent, 'related_item_title', val['title'])
        end
      end
    end

    def get_subject_genre
      vals = get_text(@mods, 'mods:subject/mods:genre')
      @metadata['keyword'] = vals if vals.any?
    end

    def get_subject_topic
      vals = get_text(@mods, 'mods:subject/mods:topic')
      @metadata['subject'] = vals if vals.any?
    end

    def get_title
      vals = get_text(@mods, 'mods:titleInfo/mods:title')
      @metadata['title'] = vals if vals.any?
    end

    def get_subtitle
      vals = get_text(@mods, 'mods:titleInfo/mods:subTitle')
      @metadata['subtitle'] = vals if vals.any?
    end

    def assign_model(typ)
      typ_downcased = typ.map { |t| t.gsub('_', ' ').gsub('-', ' ').downcase }
      # typ.any?{ |s| s.casecmp('thesis')==0 }
      if typ_downcased.include? ('journal article')
        @model = 'JournalArticle'
      elsif typ_downcased.include? ('thesis')
        @model = 'Thesis'
      else
        @model = 'Work'
      end
    end

    def get_text_with_tags(node, element)
      values = []
      node.search("./#{element}").each do |ele|
        values << ele.children.to_s
      end
      values
    end

    def get_text(node, element)
      values = []
      node.search("./#{element}").each do |ele|
        values << ele.text.strip if ele.text
      end
      values
    end

    def get_id_type_from_value(id_value)
      type = 'other'
      type = id_value.split(':', 2).first.downcase if id_value.include?(':')
      type
    end

    def get_value_by_type(node, element, default_key)
      values = {}
      node.search("./#{element}").each do |each_ele|
        typ = each_ele.xpath('@type')
        typ = default_key if typ.blank?
        values[typ.to_s] = values.fetch(typ.to_s, [])
        values[typ.to_s] << each_ele.text.strip if each_ele.text && each_ele.text.strip
      end
      values
    end

    def assign_nested_term(parent, term, value)
      @metadata["#{parent}_attributes"] = @metadata.fetch("#{parent}_attributes", [])
      vals = Hash(@metadata["#{parent}_attributes"].first)
      vals[term] = vals.fetch(term, [])
      vals[term] += Array(value)
      @metadata["#{parent}_attributes"] = [vals]
    end

    def assign_nested_hash(parent, values, merge=true)
      @metadata["#{parent}_attributes"] = @metadata.fetch("#{parent}_attributes", [])
      if merge
        vals = Hash(@metadata["#{parent}_attributes"].first)
        vals.merge!(values)
        @metadata["#{parent}_attributes"] = [vals]
      else
        @metadata["#{parent}_attributes"] << values
      end
    end

    def swap_key(values, orig_key, new_key)
      values[new_key] = values.delete(orig_key) if values.include? orig_key
      values
    end

    def assign_identifier(ids)
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

    def assign_name(names)
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
      names.each do |name_hash|
        mapped_name = {}
        if name_hash.fetch('display_form', nil)
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
        name_hash['affiliation'].each do |key, val|
          if aff_keys.include?(key.downcase)
            mapped_name[key.downcase] = mapped_name.fetch(key.downcase, [])
            mapped_name[key.downcase] += Array(val)
          else
            mapped_name['institution'] = mapped_name.fetch('institution', [])
            mapped_name['institution'] += Array(val)
          end
        end
        name_hash['identifiers'].each do |key, val|
          if id_keys.include?(key.downcase)
            mapped_name[key.downcase] = mapped_name.fetch(key.downcase, [])
            mapped_name[key.downcase] += Array(val)
          else
            mapped_name['institutional_id'] = mapped_name.fetch('institutional_id', [])
            mapped_name['institutional_id'] += Array(val)
          end
        end
        if name_hash.fetch('role', nil)
          mapped_name['role'] = Array(name_hash.fetch('role'))
        end
        assign_nested_hash('creators_and_contributors', mapped_name, merge=false)
      end
    end

  end
end
