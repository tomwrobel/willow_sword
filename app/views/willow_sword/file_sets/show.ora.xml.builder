xml.repository_file(xmlns:"http://ora.ox.ac.uk/terms/",
  'xmlns:dcterms' => "http://purl.org/dc/terms/",
  'xmlns:dc' => "http://purl.org/dc/elements/1.1/",
  'xmlns:rioxxterms' => "http://www.rioxx.net/schema/v2.0/rioxx/",
  'xmlns:foxml' => "info:fedora/fedora-system:def/foxml#",
  'xmlns:oxds' => "http://vocab.ox.ac.uk/dataset/schema#",
  'xmlns:ora' => "http://ora.ox.ac.uk/terms/",
  'xmlns:symp' => "http://symplectic/symplectic-elements:def/model#",
  'xmlns:ali' => "http://www.niso.org/schemas/ali/1.0/") do

  # Get the server path, it's a hack...
  server_path = root_url.to_s
  server_path.slice!(root_path)
  xml.content(rel:"src", href:collection_work_file_set_url(params[:collection_id], params[:work_id], @file_set))
  xml.link(rel:"edit", href:collection_work_file_set_url(params[:collection_id], params[:work_id], @file_set))
  xml.link(rel:"download", href: "#{server_path}/downloads/#{@file_set.id}")

  # Add ORA metadata
  # title
  # <dc:title>file_name M</dc:title>
  Array(@file_set.attributes.fetch('file_name', nil)).each do |val|
    xml.tag!('dc:title', val)
  end
  # format
  # <dc:format>file_format M</dc:format>
  Array(@file_set.attributes.fetch('file_format', nil)).each do |val|
    xml.tag!('dc:format', val)
  end
  # extent
  # <dcterms:extent>file_size M</dcterms:extent>
  Array(@file_set.attributes.fetch('file_size', nil)).each do |val|
    xml.tag!('dcterms:extent', val)
  end
  # hasVersion
  # <dcterms:hasVersion>file_version O</dcterms:hasVersion>
  Array(@file_set.attributes.fetch('file_version', nil)).each do |val|
    xml.tag!('dcterms:hasVersion', val)
  end
  # datastream
  # <foxml:datastream>file_admin_fedora3_datastream_identifier O</foxml:datastream>
  Array(@file_set.attributes.fetch('file_admin_fedora3_datastream_identifier', nil)).each do |val|
    xml.tag!('foxml:datastream', val)
  end
  # rioxx version
  # <rioxxterms:version>file_rioxx_version MA</rioxxterms:version>
  Array(@file_set.attributes.fetch('file_rioxx_version', nil)).each do |val|
    xml.tag!('rioxxterms:version', val)
  end
  # embargoed until
  # <oxds:embargoedUntil>file_embargo_end_date MA</oxds:embargoedUntil>
  Array(@file_set.attributes.fetch('file_embargo_end_date', nil)).each do |val|
    xml.tag!('oxds:embargoedUntil', val)
  end
  # embargo release method
  # <ora:embargoReleaseMethod>file_embargo_release_method MA</ora:embargoReleaseMethod>
  Array(@file_set.attributes.fetch('file_embargo_release_method', nil)).each do |val|
    xml.tag!('ora:embargoReleaseMethod', val)
  end
  # reason for embargo
  # <ora:reasonForEmbargo>file_embargo_reason R</ora:reasonForEmbargo>
  Array(@file_set.attributes.fetch('file_embargo_reason', nil)).each do |val|
    xml.tag!('ora:reasonForEmbargo', val)
  end
  # last access request date
  # <ora:lastAccessRequestDate>file_last_access_request_date MA</ora:lastAccessRequestDate>
  Array(@file_set.attributes.fetch('file_last_access_request_date', nil)).each do |val|
    xml.tag!('ora:lastAccessRequestDate', val)
  end
  # date file made available
  # <ora:dateFileMadeAvailable>file_made_available_date MA</ora:dateFileMadeAvailable>
  Array(@file_set.attributes.fetch('file_made_available_date', nil)).each do |val|
    xml.tag!('ali:free_to_read', 'start_date' => val)
  end
  # access condition at deposit
  # <ora:accessConditionAtDeposit>file_admin_access_condition_at_deposit MA</ora:accessConditionAtDeposit>
  Array(@file_set.attributes.fetch('file_admin_access_condition_at_deposit', nil)).each do |val|
    xml.tag!('ora:accessConditionAtDeposit', val)
  end
  # file And Record Do Not Match
  # <ora:fileAndRecordDoNotMatch>file_admin_file_and_record_do_not_match MA</ora:fileAndRecordDoNotMatch>
  Array(@file_set.attributes.fetch('file_admin_file_and_record_do_not_match', nil)).each do |val|
    xml.tag!('ora:fileAndRecordDoNotMatch', val)
  end
  # public url
  # <symp:hasPublicUrl>file_public_url MA</symp:hasPublicUrl>
  Array(@file_set.attributes.fetch('file_public_url', nil)).each do |val|
    xml.tag!('symp:hasPublicUrl', val)
  end
end

