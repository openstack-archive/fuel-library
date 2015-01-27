module Pacemaker
  module Xml
    # create a new xml document
    # @param path [String,Array<String>] create this sequence of path elements
    # @param root [REXML::Document] use existing element as a root instead of creating a new one
    # @return [REXML::Element] element point to the last path component
    # use .root to get the document root
    def xml_document(path, root = nil)
      root = REXML::Document.new unless root
      element = root
      path = Array(path) unless path.is_a? Array
      path.each do |component|
        element = element.add_element component
      end
      element
    end

    # convert hash to xml element
    # @param tag [String] what xml tag to create
    # @param hash [Hash] attributes data structure
    # @param skip_attributes [String,Array<String>] skip these hash keys
    # @param top [TrueClass,FalseClass] add 'added:top' to the xml
    # @return [REXML::Element]
    def xml_element(tag, hash, skip_attributes = nil, top = false)
      return unless hash.is_a? Hash
      element = REXML::Element.new tag
      hash = hash.merge '__crm_diff_marker__' => 'added:top' if top
      hash.each do |attribute, value|
        attribute = attribute.to_s
        # skip attributes that were specified to be skipped
        next if skip_attributes == attribute or
            (skip_attributes.respond_to? :include? and skip_attributes.include? attribute)
        # skip array and hash values. add only scalar ones
        next if value.is_a? Array or value.is_a? Hash
        element.add_attribute attribute, value
      end
      element
    end

    # output xml element as the actual xml text with indentation
    # @param element [REXML::Element]
    # @return [String]
    def xml_pretty_format(element)
      return unless element.is_a? REXML::Element
      formatter = REXML::Formatters::Pretty.new
      formatter.compact = true
      xml=''
      formatter.write element, xml
      xml + "\n"
    end
  end
end

# make rexml's attributes to be sorted by their name
# when iterating throuth them
# instead of randomly placing them each time
module REXML
  class Attributes
    def each_value # :yields: attribute
      keys.sort.each do |key|
        yield fetch key
      end
    end
  end
end
