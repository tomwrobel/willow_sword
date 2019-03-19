module WillowSword
  class CrosswalkToOra < CrosswalkToXml
    attr_reader :fileset, :doc

    def initialize(fileset)
      @fileset = fileset
      @doc = nil
    end

    def to_xml
      ora_root
      add_nodes
    end

    def ora_root
      ora = "<ora:repository_file xmlns:dc='http://purl.org/dc/elements/1.1/'
        xmlns:dcterms='http://purl.org/dc/terms/'
        xmlns:rioxxterms='http://www.rioxx.net/schema/v2.0/rioxx/'
        xmlns:foxml='info:fedora/fedora-system:def/foxml#'
        xmlns:oxds='http://vocab.ox.ac.uk/dataset/schema#'
        xmlns:ora='http://ora.ox.ac.uk/terms/'
        xmlns:symp='http://symplectic/symplectic-elements:def/model#'
        xmlns:ali='http://www.niso.org/schemas/ali/1.0/'/>"
      @doc = LibXML::XML::Document.string(ora)
    end

    def add_nodes
      translated_terms.each do |model_key, xml_tag|
        @doc.root << create_node(xml_tag, Array(@fileset[model_key])[0]) unless Array(@fileset[model_key]).blank?
      end
      unless @fileset['file_made_available_date'].blank?
        node = create_node('ali:free_to_read')
        add_attributes(node, {'start_date' => @fileset['file_made_available_date']})
        @doc.root << node
      end
    end

    def translated_terms
      {
        "file_name" => "dc:title",
        "file_format"=>"dc:format",
        "file_size"=>"dcterms:extent",
        "file_version"=>"dcterms:hasVersion",
        "file_path"=>"dcterms:location",
        "file_admin_fedora3_datastream_id"=>"foxml:datastream",
        "file_rioxx_file_version"=>"rioxxterms:version",
        "file_embargo_end_date"=>"oxds:embargoedUntil",
        "file_embargo_comment"=>"ora:embargoComment",
        "file_embargo_release_method"=>"ora:embargoReleaseMethod",
        "file_embargo_reason"=>"ora:reasonForEmbargo",
        "file_last_access_request_date"=>"ora:lastAccessRequestDate",
        "file_order"=>"ora:fileOrder",
        "access_condition_at_deposit"=>"ora:accessConditionAtDeposit",
        "file_admin_file_and_record_do_not_match"=>"ora:fileAndRecordDoNotMatch",
        "file_public_url"=>"symp:hasPublicUrl"
      }
    end

  end
end
