xml.feed(xmlns:"http://www.w3.org/2005/Atom") do
  xml.title @collection.title.join(", ")
  xml.link(rel:"edit", href:collection_works_url(@collection))
  @works.each do |work|
    xml.entry do
      xml.link(rel:"edit", href:collection_work_url(@collection, work))
    end
  end
end
