xml.feed(xmlns:"http://www.w3.org/2005/Atom") do
  xml.title @object.title.join(", ")
  # Get work
  xml.content(rel:"src", href:collection_work_url(@collection_id, @object))
  # Edit work - update metadata - not needed
  # xml.link(rel:"edit", href:collection_work_url(@collection_id, @object))
  # Add file to work
  xml.link(rel:"edit", href:collection_work_file_sets_url(@collection_id, @object))
  @object.file_set_ids.each do |file_set_id|
    xml.entry do
      # Get file metadata
      xml.content(rel:"src", href:collection_work_file_set_url(@collection_id, @object, file_set_id))
      # Edit file metadata
      xml.link(rel:"edit", href:collection_work_file_set_url(@collection_id, @object, file_set_id))
    end
  end
end
