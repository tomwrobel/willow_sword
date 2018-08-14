module WillowSword
  class ModsCrosswalk
    attr_reader :metadata
    def initialize(src_file)
      @src_file = src_file
      @mods = None
      @metadata = {}
    end

    def read_file
      return @metadata unless @src_file.present?
      return @metadata unless File.exist? @src_file
      f = File.open(@src_file) # { |conf| conf.noblanks }
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
      # get text with html tags
      @metadata['abstract'] = get_text_with_tags(mods, 'mods:abstract')
    end

    def get_access_condition
      # TODO: check assignment. license is a nested field
      @metadata['license'] = get_text_with_tags(mods, 'mods:accessCondition')
    end

    def get_etd_extension
      etd = mods.xpath('./etd:degree')
      return unless etd.present?
      @metadata['degree_name'] = get_text(etd, 'etd:name')
      @metadata['degree_level'] = get_text(etd, 'etd:level')
      @metadata['degree_institution'] = get_text(etc, 'etd:institution')
    end

    def get_genre
      # TODO: Check assignment
      @metadata['type_of_work'] = get_text(mods, 'mods:genre').downcase
    end

    def get_identifier
      ids = get_value_by_type(mods, 'mods:identifier', 'other')
      ids['source_identifiers'] = []
      ids['source_identifiers'] = ids.fetch('local', []) +
                                  ids.fetch('localidentifier', [])
      ids.delete('local')
      ids.delete('localidentifier')
      ids['isbn10'] = []
      ids['isbn13'] = []
      ids['isbn'].each do |isbn|
        isbn_length = isbn.gsub('-', '').gsub(' ', '')
        if isbn_length == 10
          ids['isbn10'] << isbn
        else
          ids['isbn13'] << isbn
        end
      end
      ids['pubs_id'] = []
      ids.select{ |k, v| k.include?('pub') }.each do |key, val|
        ids[key].each do |val|
          unless val.include? ':'
            ids['pubs_id'] << "pubs:#{val}"
          else
            ids['pubs_id'] << val
          end
        end
      end
      assign_identifier(ids)
    end

    def get_language
      @metadata['language'] = get_text(mods, 'mods:language/mods:languageTerm')
    end

    def get_name
      @metadata['name'] = []
      mods.search('./mods:name').each do |nam|
        names = {}
        # name_part
        names.merge!(get_value_by_type(nam, 'mods:namePart', 'name_part'))
        # affiliation
        names.merge!(get_value_by_type(nam, 'mods:affiliation', 'faculty'))
        # display form
        names['display_form'] = get_text(nam, 'mods:displayForm')
        # role
        names['role'] = get_text(nam, 'mods:role/mods:roleTerm')
        # extension
        names.merge!(get_value_by_type(nam, 'mods:extension', 'identifier'))
        @metadata['name'] << names
      end
    end

    def get_note
      mods.search('./mods:note').each do |note|
        typ = note.xpath('@type')
        typ = 'additionalinformation' if typ.blank?
        if typ == 'additionalinformation'
          @metadata[typ] ||= []
          @metadata[typ] << note.text.strip
        else
          label = note.xpath('@displayLabel')
          if label == 'patent-status'
            @metadata[label] ||= []
            @metadata[label] << note.text.strip
          end
        end
      end
    end

    def get_origin_info
      mods.search('./mods:originInfo').each do |origin|
        # TODO: Need to parse date text for uniformity
        # publication date
        vals = get_text(origin, 'mods:dateIssued')
        @metadata['publication_date'] = vals if vals.any?
        # copyright date
        vals = get_text(origin, 'mods:copyrightDate')
        @metadata['copyright_date'] = vals if vals.any?
        # get date by type
        vals = get_value_by_type(origin, 'mods:dateOther', 'other_date')
        vals['filed_date'] = vals.delete('filedDate') if vals.include? 'filedDate'
        vals['acceptance_date'] = vals.delete('dateOfAcceptance') if vals.include? 'dateOfAcceptance'
        @metadata.merge!(vals)
      end
    end

    def get_physical_description
      vals = get_value_by_type(mods, "mods:physicalDescription", 'other')
      vals['peer_review_status'] = vals.delete('peerReviewed') if vals.include? 'peerReviewed'
      vals['publication_status'] = vals.delete('status') if vals.include? 'dateOfAcceptance'
      # TODO: parse version to check if it is rioxx version.
      # if yes, save val with key rioxx_version
      vals.delete('other') if vals.include? 'other'
      @metadata.merge!(vals)
    end

    def get_extent
      @metadata['extent'] = get_text(mods, 'mods:physicalDescription/mods:extent')
    end

    def get_record_info
      @metadata['record_content_source'] = get_text(mods, 'mods:recordInfo/mods:recordContentSource')
    end

    def get_related_item
      mods.search('./mods:relatedItem').each do |ele|
        typ = ele.xpath('@type')
        return unless ['host', 'series'].include?(typ)
        # extract host or series values
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
        if val.any?
          @metadata[typ] ||= []
          @metadata[typ] << val
        end
      end
    end

    def get_subject_genre
      vals = get_text(mods, 'mods:subject/mods:genre')
      @metadata['keywords'] = vals if vals.any?
    end

    def get_subject_topic
      vals = get_text(mods, 'mods:subject/mods:topic')
      @metadata['subjects'] = vals if vals.any?
    end

    def get_title
      vals = get_text(mods, 'mods:titleInfo/mods:title')
      @metadata['title'] = vals if vals.any?
    end

    def get_subtitle
      vals = get_text(mods, 'mods:titleInfo/mods:subTitle')
      @metadata['subtitle'] = vals if vals.any?
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
      node.search(".#{element}").each do |ele|
        values << ele.text.strip
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
      nam.search("./#{element}").each do |each_ele|
        typ = each_ele.xpath('@type')
        typ = default_key if typ.blank?
        values[typ] ||= []
        values[typ] << each_ele.text.strip
      end
      values
    end

    def assign_identifier(ids)
      pub_attrs = {}
      pub_attrs['doi'] = ids.fetch('doi', nil)
      pub_attrs['journal_website'] = ids.fetch('publisher', nil)
      pub_attrs['chapter_number'] = ids.fetch('article_number', nil)
      pub_attrs['issn'] = ids.fetch('issn', nil)
      pub_attrs['isbn10'] = ids.fetch('isbn10', nil)
      pub_attrs['isbn13'] = ids.fetch('isbn13', nil)
      @metadata['publishers_attributes'] = [pub_attrs]
      admin_attrs = {}
      admin_attrs['identifier_at_source'] = ids.fetch('source_identifiers', nil)
      @metadata['admin_information_attributes'] = [admin_attrs]
    end

  end
end
