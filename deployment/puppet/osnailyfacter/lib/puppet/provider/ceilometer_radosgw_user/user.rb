require 'puppet/util/inifile'
require 'json'

Puppet::Type.type(:ceilometer_radosgw_user).provide(:user) do

  desc "Manage Ceilometer user in RadosGW"

  commands :rgw_adm => 'radosgw-admin'

  INI_FILENAME = '/etc/ceilometer/ceilometer.conf'

  def exists?
    radosgw_user_keys == access_keys_from_config
  end

  def create
    create_radosgw_user unless radosgw_user_keys
    set_access_keys
  end

  def destroy
    cmd = ['user', 'rm', "--uid=#{@resource[:name]}"]
    rgw_adm(cmd)
  end

  def section
    'rgw_admin_credentials'
  end

  def key_settings
    ['access_key', 'secret_key']
  end

  def radosgw_user_keys
    @radosgw_user_keys ||= get_radosgw_user_keys
  end

  def set_access_keys
    if ceilometer_file
      ceilometer_file.add_section(section, ini_filename) unless ceilometer_file.include?(section)
      radosgw_user_keys.keys.each do |key|
        ceilometer_file[section][key] = radosgw_user_keys[key]
      end
      ceilometer_file.store
    end
  end

  def ini_filename
    INI_FILENAME
  end

  def ceilometer_file
    return @ceilometer_file if @ceilometer_file
    if File.exists?(ini_filename)
      @ceilometer_file = Puppet::Util::IniConfig::File.new
      @ceilometer_file.read(ini_filename)
      @ceilometer_file
    end
  end

  def access_keys_from_config
    keys = {}
    if ceilometer_file
      key_settings.each do |setting|
        keys[setting] = ceilometer_file[section][setting] if ceilometer_file[section] && ceilometer_file[section][setting]
      end
    end
    keys
  end

  def get_radosgw_user_keys
    cmd = ['user', 'info', "--uid=#{@resource[:name]}"]
    begin
      rgw_output = rgw_adm(cmd)
    rescue Puppet::ExecutionFailure => e
      return nil if e.message =~ /could not fetch user info: no user info saved/
      raise e
    end
    parse_radosgw_output(rgw_output)
  end

  def create_radosgw_user
    cmd = ['user', 'create', "--uid=#{@resource[:name]}", "--display-name=#{@resource[:name]}"]
    rgw_adm(cmd)
    @resource[:caps].each_key do |key|
      cmd = ['caps', 'add', "--uid=#{@resource[:name]}", "--caps=#{key}=#{@resource[:caps][key]}"]
      rgw_adm(cmd)
    end
  end

  def parse_radosgw_output(rgw_output)
    keys = {}
    rgw_keys = JSON.parse(rgw_output.to_s.gsub('=>', ':')).fetch('keys', {})

    rgw_keys.each do |key|
      if key['user'] == "#{@resource[:name]}"
        keys['access_key'] = key['access_key']
        keys['secret_key'] = key['secret_key']
      end
    end
    keys
  end

end
