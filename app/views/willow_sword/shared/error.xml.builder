xml.tag!('sword:error', {
  'xmlns:sword':"http://purl.org/net/sword/",
  'xmlns:arxiv':"http://arxiv.org/schemas/atom",
  'xmlns':"http://www.w3.org/2005/Atom",
  'href':@error.iri}) do
  xml.author do
    xml.name "Sword v2 server"
  end
  xml.title "ERROR"
  xml.updated Time.now.strftime('%Y-%m-%dT%H:%M:%SZ')
  xml.generator(uri: "https://example.org/sword-app/", version: "0.1") do xml.text! 'sword@example.org' end
  xml.summary @error.message
  xml.sword :treatment, 'processing failed'
end
