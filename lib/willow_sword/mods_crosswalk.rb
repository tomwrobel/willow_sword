require 'willow_sword/mods_to_model'
module WillowSword
  class ModsCrosswalk
    attr_reader :metadata, :model, :mods, :mapped_metadata
    include ::WillowSword::ModsToModel
    def initialize(src_file)
      @src_file = src_file
      @mods = nil
      @metadata = {}
      @mapped_metadata = {}
    end

    def map_xml
      read_file
      parse_mods
      assign_mods_to_model
      assign_model
    end

    def read_file
      return @metadata unless @src_file.present?
      return @metadata unless File.exist? @src_file
      f = File.open(@src_file) # { |conf| conf.noblanks }
      doc = Nokogiri::XML(f)
      doc.remove_namespaces!
      if doc.root.name == 'modsCollection'
        @mods = doc.xpath('/modsCollection/mods')
      else
        @mods = doc.xpath('/mods')
      end
    end

    def parse_mods
      get_abstract
      get_access_condition
      # get_etd_extension
      get_genre
      get_identifier
      get_language
      get_name
      get_note
      get_origin_info
      get_physical_description
      get_record_info
      get_related_item
      get_subject_genre
      get_subject_topic
      get_subtitle
      get_type_of_resource
      get_title
      get_headers
    end

    def get_abstract
      # Map to abstract
      # get text with html tags
      vals = get_text_with_tags(@mods, 'abstract')
      @metadata['abstract'] = vals if vals.any?
    end

    def get_access_condition
      vals = get_text_with_tags(@mods, 'accessCondition')
      @metadata['access_condition'] = vals if vals.any?
    end

    def get_etd_extension
      ele = @mods.xpath('./degree')
      return unless ele.present?
      etd = {}
      # name
      vals = get_text(ele, 'etd:name')
      etd['degree_name'] = vals if vals.any?
      # level
      vals = get_text(ele, 'etd:level')
      etd['degree_level'] = vals if vals.any?
      # institution
      vals = get_text(ele, 'etd:institution')
      etd['degree_institution'] = vals if vals.any?
      # assign etd
      @metadata['etd'] = [etd] if etd.any?
    end

    def get_genre
      vals = get_text(@mods, 'genre')
      @metadata['genre'] = vals if vals.any?
    end

    def get_identifier
      vals = get_value_by_type(@mods, 'identifier', 'other')
      @metadata['identifiers'] = [vals] if vals.any?
    end

    def get_language
      vals = get_text(@mods, 'language/languageTerm')
      @metadata['language'] = vals if vals.any?
    end

    def get_name
      @metadata['names'] = []
      @mods.search('./name').each do |nam|
        name_attrs = {}
        # name_part
        vals = get_value_by_type(nam, 'namePart', 'name_part')
        name_attrs['name_parts'] = vals if vals.any?
        # affiliation
        vals = get_value_by_type(nam, 'affiliation', 'institution')
        name_attrs['affiliation'] = vals if vals.any?
        # display form
        vals = get_text(nam, 'displayForm')
        name_attrs['display_form'] = vals if vals.any?
        # role
        vals = get_text(nam, 'role/roleTerm')
        name_attrs['role'] = vals if vals.any?
        # name_identifier
        vals = get_value_by_type(nam, 'nameIdentifier', 'identifier')
        name_attrs['identifier'] = vals if vals.any?
        # assign name
        @metadata['names'] << name_attrs if name_attrs.any?
      end
    end

    def get_note
      vals = get_text(@mods, 'note')
      @metadata['notes'] = vals if vals.any?
    end

    def get_origin_info
      vals = get_text(@mods, 'originInfo/place/placeTerm')
      @metadata['place'] = vals if vals.any?
      # TODO: Need to parse date text for uniformity
      subelements = %w(publisher dateIssued dateCreated dateCaptured
        dateValid dateModified copyrightDate dateOther edition issuance frequency)
      subelements.each do |subelement|
        vals = get_text(@mods, "originInfo/#{subelement}")
        @metadata[subelement] = vals if vals.any?
      end
    end

    def get_physical_description
      vals = get_value_by_type(@mods, "physicalDescription/form", 'other')
      @metadata['form'] = [vals] if vals.any?
      vals = get_text(@mods, 'physicalDescription/extent')
      @metadata['extent'] = vals if vals.any?
    end

    def get_record_info
      subelements = %w(recordContentSource recordCreationDate recordChangeDate
        recordIdentifier recordOrigin recordInfoNote)
      @metadata['record_info'] = []
      @mods.search('./recordInfo').each do |ele|
        ri = {}
        subelements.each do |subelement|
          vals = get_text(ele, "#{subelement}")
          ri[subelement] = vals if vals.any?
        end
        @metadata['record_info'] << ri if ri.any?
      end
    end

    def get_related_item
      @metadata['related_items'] = []
      @mods.search('./relatedItem').each do |ele|
        ri = {}
        # type
        typ = ele.xpath('@type')
        ri['type_of_relationship'] = [typ.to_s] unless typ.blank?
        # title
        vals = get_text(ele, 'titleInfo/title')
        ri['related_item_title'] = vals if vals.any?
        # abstract
        vals = get_text_with_tags(ele, 'abstract')
        ri['related_item_abstract'] = vals if vals.any?
        # identifier
        vals = get_text(ele, 'identifier')
        ri['related_item_ID'] = vals if vals.any?
        @metadata['related_items'] << ri if ri.any?
      end
    end

    def get_subject_genre
      vals = get_text(@mods, 'subject/genre')
      @metadata['genre'] = vals if vals.any?
    end

    def get_subject_topic
      vals = get_text(@mods, 'subject/topic')
      @metadata['topic'] = vals if vals.any?
    end

    def get_subtitle
      vals = get_text(@mods, 'titleInfo/subTitle')
      @metadata['subtitle'] = vals if vals.any?
    end

    def get_title
      vals = get_text(@mods, 'titleInfo/title')
      @metadata['title'] = vals if vals.any?
    end

    def get_headers
      if @headers.any?
        @metadata['headers'] = stringify_keys(@headers)
      end
    end

    def get_type_of_resource
      vals = get_text(@mods, 'typeOfResource')
      @metadata['type_of_resource'] = vals if vals.any?
    end

    def assign_model
      @model = nil
      unless @metadata.fetch('type_of_resource', nil).blank?
        @model = Array(@metadata['type_of_resource']).map {
          |t| t.underscore.gsub('_', ' ').gsub('-', ' ').downcase
        }.first
      end
    end

    def get_text_with_tags(node, element)
      values = []
      node.search("./#{element}").each do |ele|
        values << ele.children.to_s
      end
      values.reject { |c| c.empty? }
    end

    def get_text(node, element)
      values = []
      node.search("./#{element}").each do |ele|
        values << ele.text.strip if ele.text
      end
      values.reject { |c| c.empty? }
    end

    def get_value_by_type(node, element, default_key)
      values = {}
      node.search("./#{element}").each do |each_ele|
        typ = each_ele.xpath('@type')
        typ = default_key if typ.blank?
        new_vals = values.fetch(typ.to_s, [])
        new_vals << each_ele.text.strip if each_ele.text && each_ele.text.strip
        values[typ.to_s] = new_vals if new_vals.any?
      end
      values
    end
  end
end
