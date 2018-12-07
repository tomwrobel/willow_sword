xml.feed(xmlns:"http://www.w3.org/2005/Atom") do
  xml.title @file_set.file_name
  # Get work
  xml.content(rel:"src", href:collection_work_file_set_url(params[:collection_id], @object, @file_set))
  # Edit work
  xml.link(rel:"edit", href:collection_work_file_set_url(params[:collection_id], @object, @file_set))
end
