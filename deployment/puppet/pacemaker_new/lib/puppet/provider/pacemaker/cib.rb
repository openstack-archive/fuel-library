module Pacemaker
  module Cib
    # get the raw CIB from Pacemaker
    # @return [String] cib xml
    def raw_cib
      return File.read @cib_file if @cib_file
      @raw_cib = cibadmin '-Q'
      if !@raw_cib or @raw_cib == ''
        fail 'Could not dump CIB XML!'
      end
      @raw_cib
    end
    attr_accessor :cib_file

    # create a new REXML CIB document
    # @return [REXML::Document] at '/'
    def cib
      return @cib if @cib
      @cib = REXML::Document.new(raw_cib)
    end

    # apply the XML patch to CIB
    # @param xml [String, REXML::Element] the patch to apply
    def cibadmin_apply_patch(xml)
      xml = xml_pretty_format xml if xml.is_a? REXML::Element
      retry_block { cibadmin_safe '--force', '--patch', '--sync-call', '--xml-text', xml.to_s }
    end

    # ask cibadmin to remove the first element matchig the input
    # @param xml [String, REXML::Element]
    def cibadmin_remove(xml)
      xml = xml_pretty_format xml if xml.is_a? REXML::Element
      retry_block { cibadmin_safe '--force', '--delete', '--sync-call', '--xml-text', xml.to_s }
    end

    # get the name of the DC node
    # @return [String, nil]
    def dc
      cib_element = cib.elements['/cib']
      return unless cib_element
      dc_node = cib_element.attribute('dc-uuid')
      return unless dc_node
      return if dc_node == 'NONE'
      dc_node.to_s
    end
  end
end
