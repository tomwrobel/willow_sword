module WillowSword
  class CrosswalkToMods < CrosswalkToXml
    attr_reader :work, :doc, :admin_doc, :rights

    def initialize(work)
      @work = work
      @doc = nil
      @admin_doc = nil
      @rights = nil
    end

    def to_xml
      to_mods
      to_admin
    end

    def to_mods
      mods_root
      add_abstract
      add_access_condition
      add_dataset_extension
      add_etd_extension
      add_genre
      add_identifier
      add_language
      add_location
      add_name
      add_note
      add_origin_info
      add_patent_extension
      add_physical_description
      add_related_item
      add_subject
      add_title
    end

    def to_admin
      admin_root
      add_embargo_info
      add_ora_admin
      add_record_info
      add_ref_admin
      add_rights_declaration
      add_thesis_admin
    end

    def mods_root
      mods = "<mods:mods version='3.8'
              xmlns:mods='http://www.loc.gov/mods/v3'
              xmlns:xs='http://www.w3.org/2001/XMLSchema'
              xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance'
              xsi:schemaLocation='http://www.loc.gov/mods/v3 https://raw.githubusercontent.com/tomwrobel/ora_data_model/master/ora_mods-3.8.xsd'/>"
      @doc = LibXML::XML::Document.string(mods)
    end

    def add_abstract
      # abstarct
      val = get_content('abstract')
      create_node_array('mods:abstract', val, @doc.root)
      # summary documentation
      val = get_child_content('bibliographic_information', 'summary_documentation')
      unless val.blank?
        node = create_node('mods:abstract', val, {'type' => 'summary_documentation'})
        @doc.root << node
      end
    end

    def add_access_condition
      fields = {
        'licence'=>'license',
        'licence_statement'=>'license_statement',
        'licence_start_date'=>'license_start_date',
        'licence_url'=>'license_url',
        'rights_statement'=>'rights_statement',
        'record_ora_deposit_licence'=>'record_ora_deposit_licence'
      }
      fields.each do |field, typ|
        parent = 'licence_and_rights_information'
        parent = 'admin_information' if field == 'record_ora_deposit_licence'
        val = get_child_content(parent, field)
        unless val.blank?
          node = create_node('mods:accessCondition', val, {'type' => typ})
          @doc.root << node
        end
      end
    end

    def add_dataset_extension
      extn = create_node('mods:extension')
      dataset_extension = "<ora_dataset:dataset
          xmlns:ora_dataset='https://ora.ox.ac.uk/vocabs/dataset'
          xmlns:mods='http://www.loc.gov/mods/v3'
          xmlns:dcterms='http://purl.org/dc/terms/'
          xmlns:dc='http://purl.org/dc/elements/1.1/'/>"
      de = LibXML::XML::Document.string(dataset_extension)
      fields = {
        'data_collection_start_date'=>['mods:dateOther', {
                                'point'=>'start',
                                'type'=>'data_collection'}],
        'data_collection_end_date'=>['mods:dateOther', {
                                'point'=>'end',
                                'type'=>'data_collection'}],
        'data_coverage_spatial'=>['dcterms:spatial'],
        'data_coverage_temporal_start_date'=>['mods:dateOther', {
                                'point'=>'start',
                                'type'=>'data_coverage'}],
        'data_coverage_temporal_end_date'=>['mods:dateOther', {
                                'point'=>'end',
                                'type'=>'data_coverage'}],
        'data_format'=>['dc:type'],
        'data_digital_storage_location'=>['ora_dataset:digital_storage_location'],
        'data_digital_data_total_file_size'=>['dcterms:extent'],
        'data_digital_data_format'=>['dc:format'],
        'data_digital_data_version'=>['dc:version'],
        'data_physical_storage_location'=>['ora_dataset:physical_storage_location'],
        'data_management_plan_url'=>['dcterms:references']
      }
      parent = 'bibliographic_information'
      fields.each do |field, tags|
        val = get_child_content(parent, field)
        unless val.blank?
          tag = tags[0]
          attribute = tags.size > 1 ? tags[1] : {}
          node = create_node(tag, val, attribute)
          de.root << node
        end
      end
      node = @doc.import(de.root)
      @doc.root << extn
      extn << node
    end

    def add_etd_extension
      extn = create_node('mods:extension')
      etd_extension = "<uketd_dc:uketddc
        xmlns:uketdterms='http://naca.central.cranfield.ac.uk/ethos-oai/terms/'
        xmlns:uketd_dc='http://naca.central.cranfield.ac.uk/ethos-oai/2.0/'
        xmlns:dcterms='http://purl.org/dc/terms/'/>"
      fields = {
        'thesis_degree_institution' => 'uketdterms:institution',
        'thesis_degree_level' => 'uketdterms:qualificationlevel',
        'thesis_degree_name' => 'uketdterms:qualificationname',
        'thesis_leave_to_supplicate_date' => 'dcterms:issued'
      }
      etd = LibXML::XML::Document.string(etd_extension)
      parent = 'bibliographic_information'
      fields.each do |field, tag|
        val = get_child_content(parent, field)
        unless val.blank?
          node = create_node(tag, val)
          etd.root << node
        end
      end
      node = @doc.import(etd.root)
      @doc.root << extn
      extn << node
    end

    def add_genre
      parent = 'item_description_and_embargo_information'
      fields = %w(type_of_work sub_type_of_work)
      fields.each do |field|
        val = get_child_content(parent, field)
        @doc.root << create_node('mods:genre', val, {'type' => field}) unless val.blank?
      end
    end

    def add_identifier
      # identifier fields
      fields = {
        'pii' => ['item_description_and_embargo_information', 'pii'],
        'identifier_pmid' => ['item_description_and_embargo_information', 'pmid'],
        'identifier_pubs_identifier' => ['item_description_and_embargo_information', 'pubs_id'],
        'tinypid' => ['item_description_and_embargo_information', 'tinypid'],
        'identifier_uuid' => ['item_description_and_embargo_information', 'uuid'],
        'identifier_source_identifier' => ['admin_information', 'source_identifier'],
        'identifier_tombstone_record_identifier' => ['admin_information', 'tombstone'],
        'paper_number' => ['bibliographic_information', 'paper_number']
      }
      fields.each do |field, tags|
        val = get_child_content(tags[0], field)
        @doc.root << create_node('mods:identifier', val, {'type' => tags[1]}) unless val.blank?
      end
      # publisher id fields
      fields = {
        'identifier_doi'=>'doi',
        'identifier_eisbn'=>'eisbn',
        'identifier_eissn'=>'eissn',
        'identifier_isbn_10'=>'isbn',
        'identifier_isbn_13'=>'isbn13',
        'identifier_issn'=>'issn'
      }
      parent = 'bibliographic_information'
      child = 'publishers'
      fields.each do |field, tag|
        val = get_grand_child_content(parent, child, field)
        @doc.root << create_node('mods:identifier', val, {'type' => tag}) unless val.blank?
      end
    end

    def add_language
      vals = get_content('language')
      unless val.blank?
        lang = create_node('mods:language')
        @doc.root << lang
        vals.each do |val|
          langterm = create_node('mods:languageTerm', val, {
            'authority' => 'iso639-2b',
            'type' => 'text'
          })
          lang << langterm
        end
      end
    end

    def add_location
      # TODO: mods:location/mods:physicalLocation
      loc = create_node('mods:location')
      @doc.root << loc
      val = get_child_content('admin_information', 'has_public_url')
      loc << create_node('mods:url', val) unless val.blank?
    end

    def add_name
      add_name_commissioning_body
      add_name_rights_holder
      add_name_funder
      add_name_publisher
      add_name_person
    end

    def add_name_commissioning_body
      parent = 'bibliographic_information'
      val = get_child_content(parent, 'commissioning_body')
      unless val.blank?
        name_node = create_node('mods:name', nil, {'type' => 'corporate'})
        @doc.root << name_node
        name_node << create_node('mods:displayForm', val)
        role_node = create_node('mods:role')
        name_node << role_node
        role_node << create_node('mods:roleTerm', 'Commissioning body', {'type' => 'text'})
      end
    end

    def add_name_rights_holder
      parent = 'license_and_rights_information'
      val = get_child_content(parent, 'rights_holders')
      unless val.blank?
        name_node = create_node('mods:name', nil, {'type' => 'corporate'})
        @doc.root << name_node
        name_node << create_node('mods:displayForm', val)
        role_node = create_node('mods:role')
        name_node << role_node
        role_node << create_node('mods:roleTerm', 'Copyright holder', {'type' => 'text'})
      end
    end

    def add_name_funder
      funders = get_content('funders')
      funders.each do |funder|
        funder_node = create_node('mods:name', nil, {'type' => 'corporate'})
        @doc.root << funder_node
        # funder_name
        val = get_content('funder_name', funder)
        funder_node << create_node('mods:displayForm', val) unless val.blank?
        # role
        role_node = create_node('mods:role')
        funder_node << role_node
        role_node << create_node('mods:roleTerm', 'Funder', {'type' => 'text'})
        # identifier
        val = get_content('funder_identifier', funder)
        funder_node << create_node('mods:nameIdentifier', val, {'type' => 'funder_identifier'}) unless val.blank?
        # affiliation - for storing grant information
        aff_node = create_node('mods:affiliation')
        funder_node << aff_node
        # grants
        funder.grant_information.each do |grant|
          funding_node = create_node('ora_admin:funding')
          add_namespaces(funding_node, {'ora_admin' => 'http://ora.ox.ac.uk/vocabs/admin'})
          funder_node << funding_node
          # funding_programme
          val = get_content('funder_funding_programme', grant)
          funding_node << create_node('ora_admin:funding_programme', val) unless val.blank?
          # funder_compliance
          val = get_content('funder_compliance_met', grant)
          funding_node << create_node('ora_admin:funder_compliance', val) unless val.blank?
          # grant
          val1 = get_content('grant_identifier', grant)
          val2 = get_content('is_funding_for', grant)
          unless val1.blank? and val2.blank?
            grant_node = create_node('ora_admin:funder_grant')
            funding_node << grant_node
            # grant_identifier
            grant_node << create_node('ora_admin:grant_identifier', val1) unless val1.blank?
            # is_funding_for
            grant_node << create_node('ora_admin:is_funding_for', val2)  unless val2.blank?
          end
        end
      end
    end

    def add_name_publisher
      parent = 'bibliographic_information'
      Array(get_child_content(parent, 'publishers')).each do |publisher|
        pub_node = create_node('mods:name', nil, {'type' => 'corporate'})
        @doc.root << pub_node
        # funder_name
        val = get_content('publisher_name', publisher)
        pub_node << create_node('mods:displayForm', val) unless val.blank?
        # role
        role_node = create_node('mods:role')
        pub_node << role_node
        role_node << create_node('mods:roleTerm', 'Publisher', {'type' => 'text'})
        # identifier
        val = get_content('publisher_website_url', publisher)
        pub_node << create_node('mods:nameIdentifier', val, {'type' => 'website'}) unless val.blank?
      end
    end

    def add_name_person
      etal_roles = []
      Array(get_content('creators_and_contributors')).each do |creator|
        val = get_content('contributor_type', creator)
        val = 'personal' if val.blank?
        nam_node = create_node('mods:name', nil, {'type' => val})
        @doc.root << nam_node
        # creator name
        val = get_content('display_name', creator)
        nam_node << create_node('mods:displayForm', val) unless val.blank?
        # given_name
        val = get_content('given_names', creator)
        nam_node << create_node('mods:namePart', val, {'type' => 'given'}) unless val.blank?
        # family_name
        val = get_content('family_name', creator)
        nam_node << create_node('mods:namePart', val, {'type' => 'family'}) unless val.blank?
        # initials
        val = get_content('initials', creator)
        nam_node << create_node('mods:alternativeName', val, {'altType' => 'initials'}) unless val.blank?
        # preferred name
        val1 = get_content('preferred_given_names', creator)
        val2 = get_content('preferred_family_name', creator)
        val3 = get_content('preferred_contributor_email', creator)
        unless val1.blank? and val2.blank? and val3.blank?
          alt_node = create_node('mods:alternativeName', nil, {'altType' => 'preferred_name'})
          nam_node << alt_node
          # given_name
          alt_node << create_node('mods:namePart', val1, {'type' => 'given'}) unless val1.blank?
          # family_name
          alt_node << create_node('mods:namePart', val2, {'type' => 'family'}) unless val2.blank?
          # initials
          alt_node << create_node('mods:nameIdentifier', val3, {'type' => 'preferred_email_address'}) unless val3.blank?
        end
        # preferred_initials
        val = get_content('preferred_initials', creator)
        unless val.blank?
          pi_node = create_node('mods:alternativeName', nil, {'altType' => 'preferred_initials'})
          nam_node << pi_node
          pi_node << create_node('mods:namePart', val)
        end
        # identifiers
        #   email_address
        val = get_content('contributor_email', creator)
        nam_node << create_node('mods:nameIdentifier', val, {
          'type' => 'email_address'
        }) unless val.blank?
        #   website
        val = get_content('contributor_website_url', creator)
        nam_node << create_node('mods:nameIdentifier', val, {
          'type' => 'website'
        }) unless val.blank?
        #   contributor_record_identifier
        val = get_content('contributor_record_identifier', creator)
        nam_node << create_node('mods:nameIdentifier', val, {
          'type' => 'contributor_record_identifier'
        }) unless val.blank?
        #   sso
        val = get_content('institutional_identifier', creator)
        nam_node << create_node('mods:nameIdentifier', val, {
          'type' => 'sso'
        }) unless val.blank?
        #   orcid_identifier
        val = get_content('orcid_identifier', creator)
        nam_node << create_node('mods:nameIdentifier', val, {
          'type' => 'orcid_identifier'
        }) unless val.blank?
        #   other identifiers
        Array(get_content('schemes', creator)).each do |scheme|
          key = get_content('contributor_identifier_scheme', scheme)
          val = get_content('contributor_identifier', scheme)
          attributes = {}
          attributes = {'type' => key} unless key.blank?
          unless attributes.blank? or val.blank?
            nam_node << create_node('mods:nameIdentifier', val, attributes)
          end
        end
        # affiliation
        node = create_node('mods:affiliation')
        nam_node << node
        aff_node = create_node('ora:affiliation')
        add_namespaces(aff_node, {'ora' => 'http://ora.ox.ac.uk/terms/'})
        node << aff_node
        #   institution
        val1 = get_content('institution', creator)
        val2 = get_content('institution_identifier', creator)
        attributes = {'type' => 'institution'}
        attributes['institution_id'] = val2 unless val2.blank?
        unless val1.blank? and val2.blank?
          aff_node << create_node('ora:affiliationComponent', val1, attributes)
        end
        #   division
        val = get_content('division', creator)
        aff_node << create_node('ora:affiliationComponent', val, {
          'type' => 'division'
        }) unless val.blank?
        #   department
        val = get_content('department', creator)
        aff_node << create_node('ora:affiliationComponent', val, {
          'type' => 'department'
        }) unless val.blank?
        #   sub_department
        val = get_content('sub_department', creator)
        aff_node << create_node('ora:affiliationComponent', val, {
          'type' => 'sub_department'
        }) unless val.blank?
        #   research_group
        val = get_content('research_group', creator)
        aff_node << create_node('ora:affiliationComponent', val, {
          'type' => 'research_group'
        }) unless val.blank?
        #   sub_unit
        val = get_content('sub_unit', creator)
        aff_node << create_node('ora:affiliationComponent', val, {
          'type' => 'sub_unit'
        }) unless val.blank?
        #   oxford_college
        val = get_content('oxford_college', creator)
        aff_node << create_node('ora:affiliationComponent', val, {
          'type' => 'oxford_college'
        }) unless val.blank?
        # roles
        Array(get_content('roles', creator)).each do |role|
          role_title = get_content('role_title', role)
          role_order = get_content('role_order', role)
          et_al = get_content('et_al', role)
          etal_roles << et_al if et_al == true
          unless role_title.blank?  and role_order.blank?
            role_node = create_node('mods:role')
            nam_node << role_node
            unless role_order.blank?
              extn_node = create_node('mods:extension')
              role_node << extn_node
              ro_node = create_node('ora:role_order', role_order)
              add_namespaces(ro_node, {'ora' => 'http://ora.ox.ac.uk/terms/'})
              extn_node << ro_node
            end
            role_node << create_node('mods:roleTerm', role_title, {'type' => 'text'})
          end
        end
      end
      # etal name block
      unless etal_roles.blank?
        nam_node = create_node('mods:name', nil, {'type' => 'personal'})
        @doc.root << nam_node
        nam_node << create_node('mods:etal')
        etal_roles.each do |etal_role|
          rol_node = create_node('mods:role')
          nam_node << rol_node
          rt_node =  create_node('mods:roleTerm', etal_role)
          rol_node << rt_node
        end
      end
    end

    def add_note
      val = get_content('additional_information')
      @doc.root << create_node('mods:note', val, {
        'displayLabel' => 'additional_information'
      }) unless val.blank?
    end

    def add_origin_info
      origin = create_node('mods:originInfo')
      @doc.root << origin
      place = create_node('mods:place')
      origin << place
      parent = 'bibliographic_information'
      child = 'publishers'
      # date issued
      val = get_grand_child_content(parent, child, 'citation_publication_date')
      origin << create_node('mods:dateIssued', val, {
        'encoding' => 'iso8601'
      }) unless val.blank?
      # date other
      val = get_grand_child_content(parent, child, 'acceptance_date')
      origin << create_node('mods:dateOther', val, {
        'type' => 'date_of_acceptance',
        'encoding' => 'iso8601'
      }) unless val.blank?
      # place
      val = get_grand_child_content(parent, child, 'citation_place_of_publication')
      place << create_node('mods:placeTerm', val, {'type' => 'text'}) unless val.blank?
      # url
      val = get_grand_child_content(parent, child, 'publication_url')
      place << create_node('mods:placeTerm', val, {'type' => 'code'}) unless val.blank?
      # copyright date
      parent = 'license_and_rights_information'
      val = get_child_content(parent, 'rights_copyright_date')
      origin << create_node('mods:copyrightDate', val, {
        'encoding' => 'iso8601'
      }) unless val.blank?
    end

    def add_patent_extension
      extn = create_node('mods:extension')
      patent_extension = "<ora_patent:patent xmlns:ora_patent='https://ora.ox.ac.uk/vocabs/patent'/>"
      fields = {
        'patent_number' => 'ora_patent:number',
        'patent_application_number' => 'ora_patent:application_number',
        'patent_publication_number' => 'ora_patent:publication_number',
        'patent_awarded_date' => 'ora_patent:awarded_date',
        'patent_filed_date' => 'ora_patent:filed_date',
        'patent_status' => 'ora_patent:status',
        'patent_territory' => 'ora_patent:territory',
        'patent_cooperative_classification' => 'ora_patent:cooperative_classification',
        'patent_european_classification' => 'ora_patent:european_classification',
        'patent_international_classification' => 'ora_patent:international_classification',
      }
      patent = LibXML::XML::Document.string(patent_extension)
      parent = 'bibliographic_information'
      fields.each do |field, tag|
        val = get_child_content(parent, field)
        unless val.blank?
          node = create_node(tag, val)
          patent.root << node
        end
      end
      node = @doc.import(patent.root)
      @doc.root << extn
      extn << node
    end

    def add_physical_description
      origin = create_node('mods:originInfo')
      @doc.root << origin
      parent = 'bibliographic_information'
      fields = %w(physical_form physical_dimensions)
      fields.each do |field|
        val = get_child_content(parent, field)
        origin << create_node('mods:form', val, {'type' => field}) unless val.blank?
      end
    end

    def add_related_item
      add_ri_event
      add_ri_ri
      add_ri_host
      add_ri_series
    end

    def add_ri_event
      events = get_child_content('bibliographic_information', 'event')
      unless events.blank?
        events.each do |event|
          ri_node = create_node('mods:relatedItem', nil, {'otherType' => 'event'})
          @doc.root << ri_node
          # event title
          val = get_content('event_title', event)
          unless val.blank?
            title_node = create_node('mods:titleInfo')
            ri_node << title_node
            title_node << create_node('mods:title', val)
          end
          # location
          val1 = get_content('event_location', event)
          val2 = get_content('event_website_url', event)
          unless val1.blank? and val2.blank?
            loc_node = create_node('mods:location')
            ri_node << loc_node
            loc_node << create_node('mods:physicalLocation', val1) unless val1.blank?
            loc_node << create_node('mods:url', val2) unless val2.blank?
          end
          # event date
          val_start = get_content('event_start_date', event)
          val_end = get_content('event_end_date', event)
          unless val_start.blank? and val_end.blank?
            ori_node = create_node('mods:originInfo')
            ri_node << ori_node
            ori_node << create_node('mods:dateOther', val_start, {
              'point' => 'start',
              'type' => 'event_date'
            }) unless val_start.blank?
            ori_node << create_node('mods:dateOther', val_end, {
              'point' => 'end',
              'type' => 'event_date'
            }) unless val_start.blank?
          end
        end
      end
    end

    def add_ri_ri
      items = get_content('related_items')
      unless items.blank?
        items.each do |item|
          ri_node = create_node('mods:relatedItem', nil, {'otherType' => 'related_item'})
          @doc.root << ri_node
          # item title
          val = get_content('related_item_title', item)
          unless val.blank?
            title_node = create_node('mods:titleInfo')
            ri_node << title_node
            title_node << create_node('mods:title', val)
          end
          # location
          val = get_content('related_item_identifier', item)
          unless val.blank?
            loc_node = create_node('mods:location')
            ri_node << loc_node
            loc_node << create_node('mods:url', val) unless val.blank?
          end
          # note
          val = get_content('related_item_citation_text', item)
          ri_node << create_node('mods:note', val, {
            'displayLabel' => 'related_item_citation_text'
          }) unless val.blank?
        end
      end
    end

    def add_ri_host
      ri_node = create_node('mods:relatedItem', nil, {'type' => 'host'})
      @doc.root << ri_node
      # host_title and journal_title
      parent = 'bibliographic_information'
      child = 'publishers'
      # title
      host_title = get_grand_child_content(parent, child, 'host_title')
      journal_title = get_grand_child_content(parent, child, 'journal_title')
      unless get_child_content(parent, child)[0].respond_to?('host_title')
        # host title and journal title
        unless host_title.blank? and journal_title.blank?
          title_node = create_node('mods:titleInfo')
          ri_node << title_node
          title_node << create_node('mods:title', host_title) unless host_title.blank?
          title_node << create_node('mods:subTitle', journal_title) unless journal_title.blank?
        end
      else
        # journal title
        unless journal_title.blank?
          title_node = create_node('mods:titleInfo')
          ri_node << title_node
          title_node << create_node('mods:title', journal_title)
        end
      end
      # part
      part_node = create_node('mods:part')
      ri_node << part_node
      #   article_number
      val = get_grand_child_content(parent, child, 'article_number')
      unless val.blank?
        detail_node = create_node('mods:detail', nil, {'type' => 'article'})
        part_node << detail_node
        detail_node << create_node('mods:number', val)
      end
      #   chapter_number
      val = get_grand_child_content(parent, child, 'chapter_number')
      unless val.blank?
        detail_node = create_node('mods:detail', nil, {'type' => 'chapter_number'})
        part_node << detail_node
        detail_node << create_node('mods:number', val)
      end
      #   edition
      val = get_grand_child_content(parent, child, 'edition')
      unless val.blank?
        detail_node = create_node('mods:detail', nil, {'type' => 'edition'})
        part_node << detail_node
        detail_node << create_node('mods:number', val)
      end
      #   issue_number
      val = get_grand_child_content(parent, child, 'issue_number')
      unless val.blank?
        detail_node = create_node('mods:detail', nil, {'type' => 'issue'})
        part_node << detail_node
        detail_node << create_node('mods:number', val)
      end
      #   pagination
      val = get_grand_child_content(parent, child, 'pagination')
      unless val.blank?
        detail_node = create_node('mods:extent', nil, {'unit' => 'pages'})
        part_node << detail_node
        detail_node << create_node('mods:list', val)
      end
      #   series_number
      val = get_grand_child_content(parent, child, 'series_number')
      unless val.blank?
        detail_node = create_node('mods:detail', nil, {'type' => 'series_number'})
        part_node << detail_node
        detail_node << create_node('mods:number', val)
      end
      #   volume
      val = get_grand_child_content(parent, child, 'volume')
      unless val.blank?
        detail_node = create_node('mods:detail', nil, {'type' => 'volume'})
        part_node << detail_node
        detail_node << create_node('mods:number', val)
      end
      # location
      val = get_grand_child_content(parent, child, 'journal_website_url')
      unless val.blank?
        loc_node = create_node('mods:location')
        ri_node << loc_node
        loc_node << create_node('mods:url', val)
      end
      # physicalDescription
      val1 = get_content('host_publication_status')
      val2 = get_content('host_peer_review_status')
      unless val1.blank? and val2.blank?
        pd_node = create_node('mods:physicalDescription')
        ri_node << pd_node
        pd_node << create_node('mods:form', val1, {'type' => 'status'}) unless val1.blank?
        pd_node << create_node('mods:form', val2, {'type' => 'peer_reviewed'}) unless val2.blank?
      end
    end

    def add_ri_series
      parent = 'bibliographic_information'
      child = 'publishers'
      series_title = get_grand_child_content(parent, child, 'series_title')
      series_number = get_grand_child_content(parent, child, 'series_number')
      # series
      unless series_title.blank? and series_number.blank?
        ri_node = create_node('mods:relatedItem', nil, {'type' => 'series'})
        @doc.root << ri_node
        # series_title
        unless series_title.blank?
          title_node = create_node('mods:titleInfo')
          ri_node << title_node
          title_node << create_node('mods:title', series_title)
        end
        # series_number
        unless series_number.blank?
          part_node = create_node('mods:part')
          ri_node << part_node
          detail_node = create_node('mods:detail', nil, {'type' => 'series_number'})
          part_node << detail_node
          detail_node << create_node('mods:number', series_number)
        end
      end
    end

    def add_subject
      val1 = get_content('keyword')
      val2 = get_content('subject')
      unless val1.blank? and val2.blank?
        subject_node = create_node('mods:subject')
        @doc.root << subject_node
        create_node_array('mods:genre', val1, subject_node) unless val1.blank?
        create_node_array('mods:topic', val2, subject_node) unless val2.blank?
      end
    end

    def add_title
      val1 = get_content('title')
      val2 = get_content('alternative_title')
      unless val1.blank? and val2.blank?
        title_node = create_node('mods:titleInfo')
        @doc.root << title_node
        create_node_array('mods:title', val1, title_node) unless val1.blank?
        title_node << create_node('mods:subTitle', val2) unless val2.blank?
      end
    end

    # ========================
    # Admin metadata
    # ========================

    def admin_root
      mods = "<mods:mods version='3.8'
              xmlns:mods='http://www.loc.gov/mods/v3'/>"
      @admin_doc = LibXML::XML::Document.string(mods)
    end

    def add_embargo_info
      fields = %w(record_embargo_end_date record_embargo_reason
                  record_embargo_release_method)
      parent = 'item_description_and_embargo_information'
      fields.each do |field|
        val = get_child_content(parent, field)
        @admin_doc.root << create_node('mods:accessCondition', val, {'type' => field}) unless val.blank?
      end
    end

    def add_ora_admin
      extn = create_node('mods:extension')
      ora_extension = "<ora_admin:admin
        xmlns:ora_admin='http://ora.ox.ac.uk/vocabs/admin'
        xmlns:dc='http://purl.org/dc/elements/1.1/'
        xmlns:dcterms='http://purl.org/dc/terms/'
        xmlns:mods='http://www.loc.gov/mods/v3'/>"
      oe = LibXML::XML::Document.string(ora_extension)
      # doi_requested
      parent = 'bibliographic_information'
      child = 'publishers'
      val = get_grand_child_content(parent, child, 'doi_requested')
      oe.root << create_node('ora_admin:doi_requested', val) unless val.blank?
      # other admin fields
      admin_fields = %w(depositor_contacted depositor_contact_email_template
      record_first_reviewed_by admin_incorrect_version_deposited record_deposit_date
      record_publication_date record_review_status record_review_status_other
      record_version rt_ticket_number)
      admin_fields.each do |fld|
        vals = get_child_content('admin_information', fld)
        label = fld
        label = 'incorrect_version_deposited' if fld == 'admin_incorrect_version_deposited'
        Array(vals).each do |val|
          oe.root << create_node("ora_admin:#{label}", val)
        end
      end
      # more admin fields
      rights_fields = %w(rights_third_party_copyright_material
                        rights_third_party_copyright_permission_received)
      parent = 'licence_and_rights_information'
      rights_fields.each do |fld|
        val = get_child_content(parent, fld)
        oe.root << create_node("ora_admin:#{fld}", val)
      end
      # history action
      ha_node = create_node('ora_admin:history')
      oe.root << ha_node
      action_fields = {
        "action_comment" => "mods:note",
        "action_date" => "dc:date",
        "action_description" => "dc:description",
        "action_duration" => "dcterms:temporal",
        "action_responsibility" => "dc:contributor"
      }
      actions = get_child_content('admin_information', 'history_information')
      actions.each do |action|
        action_node = create_node('ora_admin:history_action')
        ha_node << action_node
        action_fields.each do |data_fld, xml_fld|
          val = get_content(data_fld, action)
          action_node << create_node(xml_fld, val) unless val.blank?
        end
      end
      node = @admin_doc.import(oe.root)
      @admin_doc.root << extn
      extn << node
    end

    def add_record_info
      ri = create_node('mods:recordInfo')
      @admin_doc.root << ri
      # recordCreationDate
      val = get_child_content('admin_information', 'record_created_date')
      ri << create_node('mods:recordCreationDate', val) unless val.blank?
      # recordContentSource
      val = get_child_content('admin_information', 'record_content_source')
      ri << create_node('mods:recordContentSource', val) unless val.blank?
      info_note_fields = {
        'accept_updates' => ['record_accept_updates', 'admin_information'],
        'admin_notes' => ['admin_notes', 'admin_information'],
        'confidential_report' => ['confidential_report', 'bibliographic_information'],
        'deposit_note' => ['deposit_note', 'licence_and_rights_information'],
        'ora_data_model_version' => ['ora_data_model_version', 'admin_information'],
        'pre_counter_downloads' => ['pre_counter_downloads', 'admin_information'],
        'pre_counter_views' => ['pre_counter_views', 'admin_information'],
        'requires_review' => ['record_requires_review', 'admin_information'],
      }
      info_note_fields.each do |xml_fld, data_fld|
        val = get_child_content(data_fld[1], data_fld[0])
        ri << create_node('mods:recordInfoNote', val, {'type' => xml_fld}) unless val.blank?
      end
    end

    def add_ref_admin
      extn = create_node('mods:extension')
      oa_admin = "<ora_open_access_admin:ref_admin
         xmlns:ora_open_access_admin=\"http://ora.ox.ac.uk/vocabs/open_access_admin\"/>"
      oa = LibXML::XML::Document.string(oa_admin)
      fields = {
        'apc_admin_apc_number' => 'apc_admin_apc_number',
        'apc_admin_review_status' => 'apc_admin_apc_review_status',
        'apc_admin_spreadsheet_identifier' => 'apc_admin_apc_spreadsheet_identifier',
        'ref_compliant_at_deposit' => 'ref_compliant_at_deposit',
        'ref_compliant_availability' => 'ref_compliant_availability',
        'ref_exception_required' => 'ref_exception_required',
        'ref_exception_note' => 'ref_other_exception_note',
      }
      fields.each do |xml_fld, data_fld|
        val = get_child_content('admin_information', data_fld)
        oa.root << create_node(xml_fld, val) unless val.blank?
      end
      node = admin_doc.import(oa.root)
      @admin_doc.root << extn
      extn << node
    end

    def add_rights_declaration
      @rights = nil
      val = get_child_content('admin_information', 'record_ora_deposit_licence')
      @rights = val unless val.blank?
    end

    def add_thesis_admin
      extn = create_node('mods:extension')
      thesis_admin = "<ora_thesis:thesis_admin
         xmlns:ora_thesis='https://ora.ox.ac.uk/vocabs/thesis'/>"
      ta = LibXML::XML::Document.string(thesis_admin)
      fields = {
        'thesis_archive_version_completed' => 'thesis_archive_version_complete',
        'thesis_student_system_updated' => 'thesis_student_system_updated',
        'thesis_dispensation_from_consultation_granted' => 'thesis_dispensation_from_consultation_granted',
        'thesis_voluntary_deposit' => 'thesis_voluntary_deposit'
      }
      fields.each do |xml_fld, data_fld|
        val = get_child_content('admin_information', data_fld)
        ta.root << create_node(xml_fld, val) unless val.blank?
      end
      node = @admin_doc.import(ta.root)
      @admin_doc.root << extn
      extn << node
    end

    # ========================
    # helper methods
    # ========================

    def get_content(key, object=nil)
      object = @work if object.blank?
      object[key]
    rescue ArgumentError
      nil
    end

    def get_child_content(parent, child)
      if @work[parent].any? and not @work[parent][0].blank?
        @work[parent][0][child]
      else
        nil
      end
    rescue ArgumentError
      nil
    end

    def get_grand_child_content(parent, child, gr_child)
      if @work[parent].any? and not @work[parent][0].blank? and
         @work[parent][0][child].any? and not @work[parent][0][child][0].blank?
        @work[parent][0][child][0][gr_child]
      else
        nil
      end
    rescue ArgumentError
      nil
    end

    def create_node_array(ele, content, parent)
      Array(content).each do |val|
        parent << create_node(ele, val)
      end
    end

  end
end
