module WillowSword
  class CrosswalkFromOra
    attr_reader :ora, :metadata, :model, :mapped_metadata, :files_metadata
    def initialize(src_file, headers)
      @src_file = src_file
      @headers = headers
      @ora = nil
      @model = 'FileSet'
      @metadata = {}
      @mapped_metadata = {}
      @files_metadata = []
    end

    def map_xml
      return @metadata unless @src_file.present?
      return unless File.exist? @src_file
      File.open(@src_file) do |f|
        @ora = Nokogiri::XML(f)
      end
      @ora.remove_namespaces!
      parse_ora_xml
      @mapped_metadata = @metadata
    end

    def parse_ora_xml
      translated_terms.each do |term,mapped_value|
        vals = []
        @ora.xpath("//#{term}").each do |t|
          vals << t.text unless t.text.blank?
        end
        if term == 'extent'
          @metadata[mapped_value] = Array(vals) unless vals.blank?
        else
          @metadata[mapped_value] = Array(vals)[0] unless vals.blank?
        end
      end
      # free to read - start date
      node = @ora.xpath('//free_to_read')
      val = node.xpath('@start_date').text
      @metadata['file_made_available_date'] = val unless val.blank?
    end

    def translated_terms
      {
        'accessConditionAtDeposit' => 'access_condition_at_deposit',
        'datastream' => 'file_admin_fedora3_datastream_id',
        'embargoComment' => 'file_embargo_comment',
        'embargoReleaseMethod' => 'file_embargo_release_method',
        'embargoedUntil' => 'file_embargo_end_date',
        'extent' => 'file_size',
        'fileAndRecordDoNotMatch' => 'file_admin_file_and_record_do_not_match',
        'fileOrder' => 'file_order',
        'format' => 'file_format',
        'hasPublicUrl' => 'file_public_url',
        'hasVersion' => 'file_version',
        'lastAccessRequestDate' => 'file_last_access_request_date',
        'location' => 'file_path',
        'reasonForEmbargo' => 'file_embargo_reason',
        'title' => 'file_name',
        'version' => 'file_rioxx_file_version',
      }
    end
  end
end
