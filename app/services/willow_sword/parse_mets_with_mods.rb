module WillowSword
  module ParseMetsWithMods

    def parse_mods
      get_abstract
      get_access_condition
      get_dataset_extension
      get_etd_extension
      get_genre
      get_identifier
      get_language
      get_location
      get_name
      get_note
      get_origin_info
      get_patent_extension
      get_physical_description
      get_related_item
      get_subject_genre
      get_subject_topic
      get_subtitle
      get_title
      get_headers
    end

    def parse_admin_metadata
      get_embargo_info
      get_ora_admin
      get_record_info
      get_ref_admin
      get_rights_declaration
      get_thesis_admin
    end

    def parse_file_metadata
      # generates an array of hashes
      # hash has keys fileid, dmdid, filepath, metadata
      get_file_ids
      get_file_paths
      get_files_metadata
    end

    # ========================
    # Descriptive metadata
    # ========================
    def get_abstract
      # Map to abstract
      # get text with html tags
      vals = get_text_with_tags(@mods, 'abstract[not(@type)]')
      @metadata['abstract'] = vals if vals.any?
      vals = get_text_with_tags(@mods, "abstract[@type='summary_documentation']")
      @metadata['summary_documentation'] = vals if vals.any?
    end

    def get_access_condition
      vals = get_text_with_tags_by_attr(@mods, 'accessCondition', 'type', 'accessCondition')
      @metadata['access_condition'] = vals if vals.any?
    end

    def get_dataset_extension
      ele = @mods.xpath('./extension/dataset')
      return unless ele.present?
      # data_collection - start
      vals = get_text(ele, "dateOther[@type='data_collection'][@point='start']")
      @metadata['data_collection_start'] = vals if vals.any?
      # data_collection - end
      vals = get_text(ele, "dateOther[@type='data_collection'][@point='end']")
      @metadata['data_collection_end'] = vals if vals.any?
      # spatial
      vals = get_text(ele, "spatial")
      @metadata['dataset_spatial'] = vals if vals.any?
      # data_coverage - start
      vals = get_text(ele, "dateOther[@type='data_coverage'][@point='start']")
      @metadata['data_coverage_start'] = vals if vals.any?
      # data_coverage - end
      vals = get_text(ele, "dateOther[@type='data_coverage'][@point='end']")
      @metadata['data_coverage_end'] = vals if vals.any?
      # type
      vals = get_text(ele, "type")
      @metadata['dataset_type'] = vals if vals.any?
      # digital_storage_location
      vals = get_text(ele, "digital_storage_location")
      @metadata['digital_storage_location'] = vals if vals.any?
      # extent
      vals = get_text(ele, "extent")
      @metadata['dataset_extent'] = vals if vals.any?
      # format
      vals = get_text(ele, "format")
      @metadata['dataset_format'] = vals if vals.any?
      # version
      vals = get_text(ele, "version")
      @metadata['dataset_version'] = vals if vals.any?
      # physical_storage_location
      vals = get_text(ele, "physical_storage_location")
      @metadata['physical_storage_location'] = vals if vals.any?
      # references
      vals = get_text(ele, "references")
      @metadata['dataset_references'] = vals if vals.any?
    end

    def get_etd_extension
      ele = @mods.xpath('./extension/uketddc')
      return unless ele.present?
      # institution
      vals = get_text(ele, 'institution')
      @metadata['thesis_degree_institution'] = vals if vals.any?
      # issued
      vals = get_text(ele, 'issued')
      @metadata['thesis_leave_to_supplicate_date'] = vals if vals.any?
      # qualificationlevel
      vals = get_text(ele, 'qualificationlevel')
      @metadata['thesis_degree_level'] = vals if vals.any?
      # qualificationname
      vals = get_text(ele, 'qualificationname')
      @metadata['thesis_degree_name'] = vals if vals.any?
    end

    def get_genre
      vals = get_text(@mods, "genre[@type='type_of_work']")
      @metadata['type_of_work'] = vals if vals.any?
      vals = get_text(@mods, "genre[@type='sub_type_of_work']")
      @metadata['sub_type_of_work'] = vals if vals.any?
    end

    def get_identifier
      vals = get_text_by_type(@mods, 'identifier', 'other')
      @metadata['identifiers'] = vals if vals.any?
    end

    def get_language
      vals = get_text(@mods, 'language/languageTerm')
      @metadata['language'] = vals if vals.any?
    end

    def get_location
      vals = get_text(@mods, 'location/physicalLocation')
      @metadata['physical_location'] = vals if vals.any?
      vals = get_text(@mods, 'location/url')
      @metadata['url'] = vals if vals.any?
    end

    def get_name
      @metadata['names'] = []
      et_al_roles = []
      @mods.search('./name').each do |nam|
        name_attrs = {}
        # type
        typ = nam.xpath('@type').text
        name_attrs['type'] = typ.strip unless typ.blank?
        # affiliation
        path = 'affiliation/affiliation/affiliationComponent'
        vals = get_text_by_type(nam, path, 'other')
        name_attrs['affiliation'] = vals if vals.any?
        # affiliation - institution
        inst = []
        path = 'affiliation/affiliation/affiliationComponent[@type="institution"]'
        nam.search(path).each do |node|
          i = {}
          i['institution'] = node.text.strip unless node.text.blank?
          val = node.xpath('@institution_id').text
          i['identifier'] = val.strip unless val.blank?
          inst << i if i.any?
        end
        name_attrs['institution'] = inst if inst.any?
        # alternative name - initials
        vals = get_text(nam, "alternativeName[@altType='initials']/namePart")
        name_attrs['initials'] = vals if vals.any?
        # alternative name - preferred - given
        vals = get_text(nam, "alternativeName[@altType='preferred_name']/namePart[@type='given']")
        name_attrs['preferred_given'] = vals if vals.any?
        # alternative name - preferred - family
        vals = get_text(nam, "alternativeName[@altType='preferred_name']/namePart[@type='family']")
        name_attrs['preferred_family'] = vals if vals.any?
        # alternative name - preferred - email
        vals = get_text(nam, "alternativeName[@altType='preferred_name']/nameIdentifier[@type='preferred_email_address']")
        name_attrs['preferred_email'] = vals if vals.any?
        # alternative name - preferred - initials
        vals = get_text(nam, "alternativeName[@altType='preferred_initials']/namePart")
        name_attrs['preferred_initials'] = vals if vals.any?
        # display form
        vals = get_text(nam, 'displayForm')
        name_attrs['display_form'] = vals if vals.any?
        if nam.at_xpath('./etal')
          etal = true
        else
          etal = false
        end
        grants = []
        nam.search('./affiliation/funding').each do |funding_node|
          grant = {}
          # funding_programme
          vals = get_text(funding_node, 'funding_programme')
          grant['funding_programme'] = vals if vals.any?
          # funder_compliance
          vals = get_text(funding_node, 'funder_compliance')
          name_attrs['funder_compliance'] = vals if vals.any?
          # grant_identifier
          vals = get_text(funding_node, 'funder_grant/grant_identifier')
          grant['grant_identifier'] = vals if vals.any?
          # is_funding_for
          vals = get_text(funding_node, 'funder_grant/is_funding_for')
          grant['is_funding_for'] = vals if vals.any?
          grants << grant if grant.any?
        end
        name_attrs['grants'] = grants if grants.any?
        # name_part - given
        vals = get_text(nam, "namePart[@type='given']")
        name_attrs['given'] = vals if vals.any?
        # name_part - family
        vals = get_text(nam, "namePart[@type='family']")
        name_attrs['family'] = vals if vals.any?
        # name identifier
        vals = get_text_by_type(nam, 'nameIdentifier', 'identifier')
        name_attrs['identifier'] = vals if vals.any?
        # role
        roles = []
        nam.search("./role").each do |node|
          # roleTerm
          vals = get_text(node, 'roleTerm')
          et_al_roles << vals[0] if etal and vals.any?
          next if etal
          role = {}
          role['role_title'] = vals if vals.any?
          # roleOrder
          vals = get_text(node, 'extension/role_order')
          role['role_order'] = vals if vals.any?
          roles << role if role.any?
        end
        name_attrs['roles'] = roles if roles.any?
        # assign name
        @metadata['names'] << name_attrs if name_attrs.any?
        @metadata['et_al_roles'] = et_al_roles if et_al_roles.any?
      end
    end

    def get_note
      vals = get_text(@mods, 'note[@displayLabel="additional_information"]')
      @metadata['additional_information'] = vals if vals.any?
    end

    def get_origin_info
      # These possible child elements are not used
      #   publisher dateCreated dateCaptured dateValid
      #   dateModified edition issuance frequency
      # originInfo - copyrightDate
      vals = get_text(@mods, "originInfo/copyrightDate")
      @metadata['copyright_date'] = vals if vals.any?
      # originInfo - dateIssued
      vals = get_text(@mods, "originInfo/dateIssued")
      @metadata['date_issued'] = vals if vals.any?
      # originInfo - dateOther
      vals = get_text(@mods, 'originInfo/dateOther[@type="date_of_acceptance"]')
      @metadata['date_of_acceptance'] = vals if vals.any?
      # originInfo - place type=text
      vals = get_text(@mods, 'originInfo/place/placeTerm[@type="text"]')
      @metadata['publication_place'] = vals if vals.any?
      # originInfo - place type=code
      vals = get_text(@mods, 'originInfo/place/placeTerm[@type="code"]')
      @metadata[':publication_url'] = vals if vals.any?

    end

    def get_patent_extension
      # Fields missing in Hyrax model
      #   patent_awarded_date
      ele = @mods.xpath('./extension/patent')
      return unless ele.present?
      # number
      vals = get_text(ele, "number")
      @metadata['patent_number'] = vals if vals.any?
      # application_number
      vals = get_text(ele, "application_number")
      @metadata['patent_application_number'] = vals if vals.any?
      # publication_number
      vals = get_text(ele, "publication_number")
      @metadata['patent_publication_number'] = vals if vals.any?
      # awarded_date
      vals = get_text(ele, "awarded_date")
      @metadata['patent_awarded_date'] = vals if vals.any?
      # filed_date
      vals = get_text(ele, "filed_date")
      @metadata['patent_filed_date'] = vals if vals.any?
      # status
      vals = get_text(ele, "status")
      @metadata['patent_status'] = vals if vals.any?
      # territory
      vals = get_text(ele, "territory")
      @metadata['patent_territory'] = vals if vals.any?
      # cooperative_classification
      vals = get_text(ele, "cooperative_classification")
      @metadata['patent_cooperative_classification'] = vals if vals.any?
      # european_classification
      vals = get_text(ele, "european_classification")
      @metadata['patent_european_classification'] = vals if vals.any?
      # international_classification
      vals = get_text(ele, "international_classification")
      @metadata['patent_international_classification'] = vals if vals.any?
    end

    def get_physical_description
      vals = get_text_by_type(@mods, "physicalDescription/form", 'other')
      @metadata['form'] = vals if vals.any?
    end

    def get_related_item
      @metadata['related_items'] = []
      @mods.search('./relatedItem').each do |ele|
        ri = {}
        # type
        typ = ele.xpath('@type').text
        ri['type'] = typ.strip unless typ.blank?
        # otherType
        typ = ele.xpath('@otherType').text
        ri['other_type'] = typ unless typ.blank?
        # abstract
        vals = get_text_with_tags(ele, 'abstract')
        ri['related_item_abstract'] = vals if vals.any?
        # dateOther - event start date
        vals = get_text(ele, "originInfo/dateOther[@type='event_date'][@point='start']")
        ri['related_item_event_start_date'] = vals
        # dateOther - event end date
        vals = get_text(ele, "originInfo/dateOther[@type='event_date'][@point='end']")
        ri['related_item_event_end_date'] = vals
        # identifier
        vals = get_text(ele, 'identifier')
        ri['related_item_ID'] = vals if vals.any?
        # note - related_item_citation_text
        vals = get_text(ele, "note[@displayLabel='related_item_citation_text']")
        ri['related_item_citation_text'] = vals
        # part - article_number
        vals = get_text(ele, "part/detail[@type='article']/number")
        ri['related_item_article_number'] = vals if vals.any?
        # part - chapter_number
        vals = get_text(ele, "part/detail[@type='chapter_number']/number")
        ri['related_item_chapter_number'] = vals if vals.any?
        # part - edition
        vals = get_text(ele, "part/detail[@type='edition']/number")
        ri['related_item_edition'] = vals if vals.any?
        # part - issue
        vals = get_text(ele, "part/detail[@type='issue']/number")
        ri['related_item_issue'] = vals if vals.any?
        # part - pages
        vals = get_text(ele, "part/extent[@unit='pages']/list")
        ri['related_item_pages'] = vals if vals.any?
        # part - series_number
        vals = get_text(ele, "part/detail[@type='series_number']/number")
        ri['related_item_series_number'] = vals if vals.any?
        # part - volume
        vals = get_text(ele, "part/detail[@type='volume']/number")
        ri['related_item_volume'] = vals if vals.any?
        # physicalDescription - form - status
        vals = get_text(ele, "physicalDescription/form[@type='status']")
        ri['related_item_status'] = vals if vals.any?
        # physicalDescription - form - peer_reviewed
        vals = get_text(ele, "physicalDescription/form[@type='peer_reviewed']")
        ri['related_item_peer_reviewed'] = vals if vals.any?
        # physical_location
        vals = get_text(ele, 'location/physicalLocation')
        ri['related_item_physical_location'] = vals if vals.any?
        # subtitle
        vals = get_text(ele, 'titleInfo/subTitle')
        ri['related_item_subtitle'] = vals if vals.any?
        # title
        vals = get_text(ele, 'titleInfo/title')
        ri['related_item_title'] = vals if vals.any?
        # url
        vals = get_text(ele, 'location/url')
        ri['related_item_url'] = vals if vals.any?
        # Assign related item
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
        @metadata['headers'] = @headers.stringify_keys
      end
    end

    # ========================
    # Admin metadata
    # ========================
    def get_embargo_info
      ele = @amd.xpath('sourceMD/mdWrap/xmlData/mods')
      vals = get_text_by_type(ele, 'accessCondition', 'other')
      @metadata['embargo_info'] = vals if vals.any?
    end

    def get_ora_admin
      ele = @amd.xpath('sourceMD/mdWrap/xmlData/mods/extension/admin')
      fields = %w(doi_requested depositor_contacted depositor_contact_email_template
      record_first_reviewed_by incorrect_version_deposited record_deposit_date
      record_publication_date record_review_status record_review_status_other
      record_version rights_third_party_copyright_material rt_ticket_number
      rights_third_party_copyright_permission_received)
      ri = {}
      fields.each do |field|
        vals = get_text(ele, field)
        ri[field] = vals if vals.any?
      end
      # get history actions
      history_actions = []
      ele.search("./history/history_action").each do |action_ele|
        history_action = {}
        action_fields = %w(note date description temporal contributor)
        action_fields.each do |action_field|
          vals = get_text(action_ele, action_field)
          history_action[action_field] = vals if vals.any?
        end
        history_actions << history_action if history_action.any?
      end
      ri['history_actions'] = history_actions if history_actions.any?
      @metadata['admin_info'] = ri if ri.any?
    end

    def get_record_info
      ele = @amd.xpath('sourceMD/mdWrap/xmlData/mods/recordInfo')
      return unless ele.present?
      fields = %w(recordContentSource recordCreationDate)
      fields.each do |field|
        vals = get_text(ele, field)
        @metadata[field] = vals if vals.any?
      end
      # recordInfoNote
      vals = get_text_by_type(ele, 'recordInfoNote', 'other')
      @metadata['recordInfoNote'] = vals if vals.any?
    end

    def get_ref_admin
      ele = @amd.xpath('sourceMD/mdWrap/xmlData/mods/extension/ref_admin')
      fields = %w(apc_admin_apc_number apc_admin_review_status apc_admin_spreadsheet_identifier
      ref_compliant_at_deposit ref_compliant_avialability ref_exception_required
      ref_exception_note)
      ra = {}
      fields.each do |field|
        vals = get_text(ele, field)
        ra[field] = vals if vals.any?
      end
      @metadata['ref_admin'] = ra if ra.any?
    end

    def get_rights_declaration
      vals = get_text_with_tags(@amd, 'rightsMD/mdWrap/xmlData/RightsDeclarationMD/RightsDeclaration')
      @metadata['record_ora_deposit_licence'] = vals if vals.any?
    end

    def get_thesis_admin
      ele = @amd.xpath('sourceMD/mdWrap/xmlData/mods/extension/thesis_admin')
      fields = %w(thesis_archive_version_completed thesis_student_system_updated
      thesis_dispensation_from_consultation_granted thesis_voluntary_deposit)
      ta = {}
      fields.each do |field|
        vals = get_text(ele, field)
        ta[field] = vals if vals.any?
      end
      @metadata['thesis_admin'] = ta if ta.any?
    end

    # ========================
    # File metadata
    # ========================
    def get_file_ids
      @mets.search("./mets/structMap/div/div").each do |ele|
        file_data = {}
        dmdid = ele.xpath("@DMDID").text
        file_data['dmdid'] = dmdid unless dmdid.blank?
        fptr = ele.xpath('./fptr')
        fileid = fptr.xpath("@FILEID").text
        file_data['fileid'] = fileid unless fileid.blank?
        @files_metadata << file_data if file_data.any?
      end
    end

    def get_file_paths
      return unless @files_metadata.any?
      require 'uri'
      @files_metadata.each do |f|
        fileid = f.fetch('fileid', nil)
        next if fileid.blank?
        locations = @mets.xpath("./mets/fileSec/fileGrp/file[@ID='#{fileid}']/FLocat")
        paths = []
        locations.each do |loc|
          path = loc.xpath('@href').text
          paths << URI(path).path unless path.blank?
        end
        f['filepath'] = paths if paths.any?
      end
    end

    def get_files_metadata
      return unless @files_metadata.any?
      @files_metadata.each do |f|
        dmdid = f.fetch('dmdid', nil)
        next if dmdid.blank?
        ele = @mets.xpath("./mets/dmdSec[@ID='#{dmdid}']")
        file_metadata = get_file_metadata(ele)
        f['metadata'] = file_metadata if file_metadata.any?
      end
    end

    def get_file_metadata(ele)
      file_ele = ele.xpath('./mdWrap/xmlData/repository_file')
      fields = %w(title format extent hasVersion location datastream version
                  embargoedUntil embargoComment embargoReleaseMethod reasonForEmbargo
                  lastAccessRequestDate fileOrder accessConditionAtDeposit
                  fileAndRecordDoNotMatch hasPublicUrl)
      file_metadata = {}
      fields.each do |field|
        vals = get_text(file_ele, field)
        file_metadata[field] = vals unless vals.blank?
      end
      dates = []
      file_ele.xpath("./free_to_read").each do |fr|
        dt = fr.xpath('@start_date').text
        dates << dt unless dt.blank?
      end
      file_metadata['start_date'] = dates if dates.any?
      file_metadata
    end

    def assign_model
      type_of_work = @metadata.fetch('type_of_work', nil)
      unless type_of_work.blank?
        @model = Array(type_of_work).map {
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

    def get_text_by_type(node, element, default_key)
      get_text_by_attr(node, element, 'type', default_key)
    end

    def get_text_by_attr(node, element, tag, default_key)
      values = {}
      node.search("./#{element}").each do |ele|
        typ = ele.xpath("@#{tag}")
        typ = default_key if typ.blank?
        new_vals = values.fetch(typ.to_s, [])
        new_vals << ele.text.strip if ele.text && ele.text.strip
        values[typ.to_s] = new_vals if new_vals.any?
      end
      values
    end

    def get_text_with_tags_by_attr(node, element, tag, default_key)
      values = {}
      node.search("./#{element}").each do |ele|
        typ = ele.xpath("@#{tag}")
        typ = default_key if typ.blank?
        new_vals = values.fetch(typ.to_s, [])
        new_vals << ele.children.to_s
        new_vals.reject { |c| c.empty? }
        values[typ.to_s] = new_vals if new_vals.any?
      end
      values
    end

  end
end
