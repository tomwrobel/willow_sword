xml.feed(xmlns:"http://www.w3.org/2005/Atom",
  'xmlns:dcterms':"http://purl.org/dc/terms/",
  'xmlns:dc':"http://purl.org/dc/elements/1.1/") do
  Array(@file_set.title).each do |t|
    xml.title t
  end
  xml.content(rel:"src", href:collection_work_file_set_url(params[:collection_id], params[:work_id], @file_set))
  xml.link(rel:"edit", href:collection_work_file_set_url(params[:collection_id], params[:work_id], @file_set))

  # Add dc metadata
  xw = WillowSword::DcCrosswalk.new(nil)
  @file_set.attributes.each do |attr, values|
    if xw.terms.include?(attr.to_s)
      term = xw.translated_terms.key(attr.to_s).present? ? xw.translated_terms.key(attr.to_s) : attr.to_s
      Array(values).each do |val|
        xml.dc term.to_sym, val
      end
    end
  end
end
