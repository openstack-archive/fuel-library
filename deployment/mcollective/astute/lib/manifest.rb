class Template
  def self.p_(value)
    if value.is_a? Hash
      return self._hash(value)
    end
    if value.is_a? Array
      return self._list(value)
    end
    if value.is_a? TrueClass or value.is_a? FalseClass
      return value.to_s
    end
    if value.is_a? Integer
      return value.to_s
    end
    if value.nil?
      return 'undef'
    end
    self._str(value)
  end

  def self._hash(value)
    '{%s}' % value.collect() do |k, v|
      "%s => %s" % [self.p_(k), self.p_(v)]
    end.join(',')
  end

  def self._list(value)
    '[%s]' % value.collect() do |k|
      "%s" % self.p_(k)
    end.join(",")
  end

  def self._str(value)
    ret = value.to_s()
    if ret[0..0] == '$'
      return ret
    end
    "'%s'" % ret
  end

  def self._replace(template, key, value)
    if template.gsub!(/^(\$#{key})\s*=.*/, "\\1 = " + self.p_(value)).nil?
      raise ArgumentError, "Variable '#{key}' not found"
    end
    template
  end

  def initialize(path)
    @value = File.read(path)
  end

  def replace(hash)
    hash.each do |key, value|
      @value = Template._replace(@value, key, value)
    end
    self
  end

  def to_s()
    @value.to_s()
  end
end

class ConfigYaml
  def initialize(yaml)
    ConfigYaml.validate(yaml)
    @yaml=yaml
  end
  def self.validate(yaml)

  end
  def self.load_file(path)
    require 'yaml'
    return ConfigYaml.new(YAML.load_file(path))
  end
  def common()
    @yaml['common']
  end
  def settings()
    self.common()['openstack_common']
  end
  def mandatory(key)
    result = self.settings()[key]
    if result.nil?
      raise "Undefined %s" % key
    end
    result
  end
  def obligatory(key)
    self.settings()[key]
  end
  def internal_virtual_ip()
    self.mandatory('internal_virtual_ip')
  end
  def public_virtual_ip()
    self.mandatory('public_virtual_ip')
  end
  def floating_range()
    self.obligatory('floating_range')
  end
  def fixed_range()
    self.mandatory('fixed_range')
  end
  def mirror_type()
    self.mandatory('mirror_type')
  end
  def template()
    self.obligatory('template')
  end
  def quantums()

  end
  def quantum()
    self.mandatory('quantum')
  end
  def swift_proxies()

  end
  def controllers()

  end
  def loopback()
    self.mandatory('loopback')
  end
  def cinder()
    self.mandatory('cinder')
  end
  def cinder_on_computes()
    self.mandatory('cinder_on_computes')
  end
  def use_syslog()
    self.mandatory('use_syslog')
  end
  def swift()
    self.mandatory('swift')
  end
  def default_gateway()
    self.mandatory('default_gateway')
  end
  def nagios_master()
    self.mandatory('nagios_master')
  end
  def public_interface()
    self.mandatory('public_interface')
  end
  def internal_interface()
    self.mandatory('internal_interface')
  end
  def private_interface()
    self.mandatory('private_interface')
  end
  def nv_physical_volumes()
    self.mandatory('nv_physical_volumes')
  end
  def segment_range()
    self.mandatory('segment_range')
  end
  def external_ip_info()
    self.mandatory('external_ip_info')
  end
  def dns_nameservers()
    self.mandatory('dns_nameservers')
  end
  def nodes()
    self.mandatory('nodes')
  end
end

class Manifest
  def self.prepare_manifest(template, config)
    template.replace(:internal_virtual_ip => config.internal_virtual_ip(),
                     :public_virtual_ip => config.public_virtual_ip(),
                     :floating_range => config.floating_range(),
                     :fixed_range => config.fixed_range(),
                     :mirror_type => config.mirror_type(),
                     :public_interface => config.public_interface(),
                     :internal_interface => config.internal_interface(),
                     :private_interface => config.private_interface(),
                     :nv_physical_volume => config.nv_physical_volumes(),
                     :use_syslog => config.use_syslog(),
                     :cinder => config.cinder(),
                     :cinder_on_computes => config.cinder_on_computes(),
                     :nagios_master => config.nagios_master(),
                     :external_ipinfo => config.external_ip_info(),
                     :nodes => config.nodes(),
                     :dns_nameservers => config.dns_nameservers(),
                     :default_gateway => config.default_gateway(),
                     :segment_range => config.segment_range()
    )

    if config.swift()
      template.replace(:swift_loopback => config.loopback())
    end
    template.replace(:quantum => config.quantum())
  end
end