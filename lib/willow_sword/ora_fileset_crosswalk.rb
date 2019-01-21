module WillowSword
  class OraFilesetCrosswalk
    attr_reader :metadata, :model, :terms, :translated_terms, :singular
    def initialize(src_file)
      @src_file = src_file
      @metadata = {}
    end

    def translated_terms
      {
          'datastream' => 'file_admin_fedora3_datastream_identifier',
          'embargoedUntil' => 'file_embargo_end_date',
          'embargoReason' => 'file_embargo_reason',
          'embargoReleaseMethod' => 'file_embargo_release_method',
          'dateFileMadeAvailable' => 'file_made_available_date',
          'extent' => 'file_size',
          'free_to_read' => 'file_made_available_date',
          'hasPublicUrl' => 'file_public_url',
          'format' => 'file_format',
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
          values << t.text if t.text.present?
        end
        values = values.first if values.present?
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

