require 'libxml'

module WillowSword
  class CrosswalkToXml
    def create_doc_xml(root)
      doc = LibXML::XML::Document.new
      doc.encoding = LibXML::XML::Encoding::UTF_8
      doc.root = LibXML::XML::Node.new(root)
      doc
    end

    def add_namespaces(node, namespaces)
      #pass nil as the prefix to create a default node
      default = namespaces.delete( "default" )
      node.namespaces.namespace = LibXML::XML::Namespace.new( node, nil, default ) unless default.blank?
      namespaces.each do |prefix, prefix_uri|
        LibXML::XML::Namespace.new( node, prefix, prefix_uri )
      end
      node
    end

    def create_node(name, content=nil, attributes={})
      node = LibXML::XML::Node.new(name)
      node.content = content.to_s unless content.blank?
      add_attributes(node, attributes) unless attributes.blank?
      node
    end

    def set_node_namespace(node, prefix)
      ns = node.namespaces.find_by_prefix(prefix)
      node.namespaces.namespace = ns
      node
    end

    def add_attributes(node, attributes={}, attribute_prefixes={})
      attributes.each do |key, value|
        attribute = LibXML::XML::Attr.new(node, key, value)
        attribute_prefix = attribute_prefixes.fetch(key, nil)
        unless attribute_prefix.blank?
          ns = node.namespaces.find_by_prefix(attribute_prefix)
          attribute.namespaces.namespace = ns
        end
      end
      node
    end
  end
end
