module WillowSword
  class OraFilesetCrosswalk
    attr_reader :metadata, :model, :terms, :translated_terms, :singular
    def initialize(src_file)
      @src_file = src_file
      @metadata = {}
    end

    def translated_terms
      {
        'accessConditionAtDeposit' => 'access_condition_at_deposit',
        'datastream' => 'file_admin_fedora3_datastream_identifier',
        'embargoComment' => 'file_embargo_comment',
        'embargoReleaseMethod' => 'file_embargo_release_method',
        'embargoedUntil' => 'file_embargo_end_date',
        'extent' => 'file_size',
        'fileOrder' => 'file_order',
        'fileAndRecordDoNotMatch' => 'file_admin_file_and_record_do_not_match',
        'format' => 'file_format',
        'hasPublicUrl' => 'file_public_url',
        'hasVersion' => 'file_version',
        'lastAccessRequestDate' => 'file_last_access_request_date',
        'location' => 'file_path',
        'reasonForEmbargo' => 'file_embargo_reason',
        'title' => 'file_name',
        'version' => 'file_rioxx_version'
      }
    end

    def map_xml
      return @metadata unless @src_file.present?
      return @metadata unless File.exist? @src_file
      f = File.open(@src_file)
      doc = Nokogiri::XML(f)
      # doc = Nokogiri::XML(@xml_metadata)
      doc.remove_namespaces!
      translated_terms.each do |term,mapped_value|
        values = []
        doc.xpath("//#{term}").each do |t|
          values << t.text unless t.text.blank?
        end
        values = values.first unless values.blank?
        @metadata[mapped_value] = values unless values.blank?
      end
      f.close
      assign_model
    end

    def assign_model
      @model = nil
      unless @metadata.fetch(:resource_type, nil).blank?
        @model = Array(@metadata[:resource_type]).map {
            |t| t.underscore.gsub('_', ' ').gsub('-', ' ').downcase
        }.first
      end
    end

  end
end

