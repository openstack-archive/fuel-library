require 'puppet/provider/parsedfile'

Puppet::Type.type(:nova_config).provide(
  :configfile,
  :parent => Puppet::Provider::ParsedFile,
  :default_target => Puppet::Type.type(:nova_config).default_target,
  :filetype => :flat
) do

  confine :osfamily => [:debian, :redhat]
  defaultfor :operatingsystem => :debian

  #confine :exists => novaconf
  text_line :comment, :match => /#|\[.*/;
  text_line :blank, :match => /^\s*$/;

  record_line :parsed,
    :fields => %w{line},
    :match => /(.*)/ ,
    :post_parse => proc { |hash|
      Puppet.debug("nova config line:#{hash[:line]} has been parsed")
      if hash[:line] =~ /^\s*(\S+?)\s*=\s*([\S ]+?)\s*$/
        hash[:name]=$1
        hash[:value]=$2
      elsif hash[:line] =~ /^\s*(\S+)\s*$/
        hash[:name]=$1
        hash[:value]=false
      else
        raise Puppet::Error, "Invalid line: #{hash[:line]}"
      end
    }

  def self.to_line(hash)
    if hash[:name] and hash[:value]
      "#{hash[:name]}=#{hash[:value]}"
    end
  end

  def self.header
    "# Auto Genarated Nova Config File\n[DEFAULT]\n"
  end

end
