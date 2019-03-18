module WillowSword
  module ExtractMetadata
    extend ActiveSupport::Concern

    def extract_metadata(file_path, type)
      @attributes = nil
      @files_attributes = nil
      return unless File.exist?(file_path)
      if type == 'work'
        xw_klass = WillowSword.config.xw_from_xml_for_work
      elsif type == 'fileset'
        xw_klass = WillowSword.config.xw_from_xml_for_fileset
      end
      xw = xw_klass.new(file_path, @headers)
      xw.map_xml
      @attributes = xw.mapped_metadata
      @files_attributes = xw.files_metadata
      @resource_type = xw.model unless @attributes.blank?
    end
  end
end
