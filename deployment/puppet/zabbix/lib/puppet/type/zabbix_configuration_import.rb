require 'puppet/util/filetype'
require 'digest/md5'

Puppet::Type.newtype(:zabbix_configuration_import) do
  desc <<-EOT
    Import Zabbix configuration from a file.
  EOT

  ensurable
  # do
  #   defaultvalues
  #   defaultto :present
  # end

  newparam(:name, :namevar => true) do
    desc 'Name of import.'
  end

  newparam(:api) do
    desc 'Zabbix api info: endpoint, username, password.'
  end

  newproperty(:xml_file) do
    desc 'xml file'

    validate do |value|
      unless Pathname.new(value).absolute?
        fail("Invalid xml_file #{value}")
      end
    end

    def insync?(is)
      xml_file_content = Puppet::Util::FileType.filetype(:flat).new(value).read
      if is == Digest::MD5.hexdigest(xml_file_content)
        true
      else
        false
      end
    end

  end

  autorequire(:file) do
    [@parameters[:xml_file]]
  end

end
