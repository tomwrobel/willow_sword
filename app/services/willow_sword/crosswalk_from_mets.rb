module WillowSword
  class CrosswalkFromMets

    attr_reader :mets, :metadata, :model, :mapped_metadata, :files_metadata
    include WillowSword::ParseMetsWithMods
    include WillowSword::AssignMetsToModel

    def initialize(src_file, headers)
      @src_file = src_file
      @headers = headers
      @mets = nil
      @model = nil
      @metadata = {}
      @mapped_metadata = {}
      @files_metadata = []
      # contains a hash with the keys fileid, dmdid, filepath, metadata
    end

    def map_xml
      return unless @src_file.present?
      return unless File.exist? @src_file
      # f = File.open(@src_file)
      File.open(@src_file) do |f|
        @mets = Nokogiri::XML(f)
      end
      @mets.remove_namespaces!
      @mods = @mets.xpath("/mets/dmdSec/mdWrap/xmlData/mods")
      @amd = @mets.xpath("/mets/amdSec")
      parse_mods
      parse_admin_metadata
      parse_file_metadata
      assign_mets_to_model if @metadata.any?
      assign_files_metadata if @files_metadata.any?
    end

  end
end
