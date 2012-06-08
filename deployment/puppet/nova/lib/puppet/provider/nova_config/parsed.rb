require 'puppet/provider/parsedfile'

novaconf = "/etc/nova/nova.conf"

Puppet::Type.type(:nova_config).provide(
  :parsed,
  :parent => Puppet::Provider::ParsedFile,
  :default_target => novaconf,
  :filetype => :flat
) do

  confine :osfamily => [:debian] 

  #confine :exists => novaconf
  text_line :comment, :match => /^\s*#/;
  text_line :blank, :match => /^\s*$/;

  record_line :parsed,
    :fields => %w{line},
    :match => /--(.*)/ ,
    :post_parse => proc { |hash|
      Puppet.debug("nova config line:#{hash[:line]} has been parsed")
      if hash[:line] =~ /^\s*(\S+?)\s*=\s*([\S ]+)\s*$/
        hash[:name]=$1
        hash[:value]=$2
      elsif hash[:line] =~ /^\s*no(\S+)\s*$/
        hash[:name]=$1
        hash[:value]=false
      elsif hash[:line] =~ /^\s*(\S+)\s*$/
        hash[:name]=$1
        hash[:value]=true
      else
        raise Puppet::Error, "Invalid line: #{hash[:line]}"
      end
    }

  def self.to_line(hash)
    "--#{hash[:name]}=#{hash[:value]}"
  end

end
