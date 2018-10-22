xml.feed(xmlns:"http://www.w3.org/2005/Atom") do
  xml.title @object.title.join(", ")
  # Get work
  xml.content(rel:"src", href:collection_work_url(@collection_id, @object))
  # Edit work - update metadata - not needed
  xml.link(rel:"edit", href:collection_work_url(@collection_id, @object))
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
  # Add MODS metadata
  # x.Hello("World!", "type" => "global")
  xml.mods({'xmlns:xlink':'http://www.w3.org/1999/xlink',
    'version':'3.4',
    'xmlns:xsi':'http://www.w3.org/2001/XMLSchema-instance',
    'xmlns':'http://www.loc.gov/mods/v3',
    'xsi:schemaLocation':'http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-4.xsd'
  }) do
    # ---- Abstract
    Array(@object[:abstract]).each do |val|
      xml.abstract(val)
    end
  end
end
