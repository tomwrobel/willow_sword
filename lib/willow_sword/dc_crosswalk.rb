module WillowSword
  class DcCrosswalk
    attr_reader :metadata
    def initialize(src_file)
      @src_file = src_file
      @metadata = {}
      map_xml
    end
    def map_xml
      return metadata unless File.exist? @src_file
      f = File.open(@src_file)
      doc = Nokogiri::XML(f)
      # doc = Nokogiri::XML(@xml_metadata)
      doc.remove_namespaces!
      terms = %w(abstract accessRights accrualMethod accrualPeriodicity
        accrualPolicy alternative audience available bibliographicCitation
        conformsTo contributor coverage created creator date dateAccepted
        dateCopyrighted dateSubmitted description educationLevel extent
        format hasFormat hasPart hasVersion identifier instructionalMethod
        isFormatOf isPartOf isReferencedBy isReplacedBy isRequiredBy issued
        isVersionOf language license mediator medium modified provenance
        publisher references relation replaces requires rights rightsHolder
        source spatial subject tableOfContents temporal title type valid)
      terms.each do |term|
        values = []
        doc.xpath("//#{term}").each do |t|
          values << t.text if t.text.present?
        end
        @metadata[term.to_sym] = values unless values.blank?
      end
      f.close
    end
  end
end
