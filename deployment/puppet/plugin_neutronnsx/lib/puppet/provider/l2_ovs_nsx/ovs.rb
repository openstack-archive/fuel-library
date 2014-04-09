require 'net/https'
require 'rubygems'
require 'json'

Puppet::Type.type(:l2_ovs_nsx).provide(:ovs) do

  commands :vsctl => '/usr/bin/ovs-vsctl'
  commands :vspki => '/usr/bin/ovs-pki'

  def generate_cert
    @cert_dir = "/etc/openvswitch"
    @cert_path = "#{@cert_dir}/ovsclient-cert.pem"
    @privkey_path = "#{@cert_dir}/ovsclient-privkey.pem"
    @cacert_path = "#{@cert_dir}/vswitchd.cacert"
    vsctl("set-manager", "ssl:#{@resource[:nsx_endpoint].split(',')[0].strip}")
    if not File.exists? @cert_path
      old_dir = Dir.pwd
      Dir.chdir @cert_dir
      vspki("init", "--force")
      vspki("req+sign", "ovsclient", "controller")
      vsctl("--", "--bootstrap", "set-ssl", "#{@privkey_path}", "#{@cert_path}", "#{@cacert_path}")
      Dir.chdir old_dir
    end
  end

  def get_cert
    if File.exists? @cert_path
      cert_file = File.open(@cert_path, "r")
      cert_contents = cert_file.read
      cert = cert_contents.gsub(/.*?(?=-*BEGIN CERTIFICATE-*)/m, "")
      return cert
    end
    return nil
  end

  def login
    conn = Net::HTTP.new(@resource[:nsx_endpoint].split(',')[0],443)
    conn.use_ssl = true
    conn.verify_mode = OpenSSL::SSL::VERIFY_NONE
    resp, data = conn.post('/ws.v1/login', "username=#{@resource[:nsx_username]}&password=#{@resource[:nsx_password]}", {'Content-Type' => 'application/x-www-form-urlencoded'})
    cookie = resp.response['set-cookie'].split('; ')[0]
    return conn, cookie
  end

  def get_uuid
    resp, data = @conn.get('/ws.v1/transport-node', { 'Cookie' => @cookie })
    nodes = JSON.load(data)['results']
    nodes.each { |node|
      resp, data = @conn.get(node['_href'], { 'Cookie' => @cookie })
      if JSON.load(data)['display_name'] == @resource[:display_name]
        return JSON.load(data)['uuid']
      end
    }
    return nil
  end

  def exists?
    @conn, @cookie = login
    query_result = get_uuid
    unless query_result.nil?
      return true
    end
    return false
  end

  def create
    generate_cert
    cert = get_cert
    bridge_ip = @resource[:ip_address].split("/")[0]
    connector_mapping = {
                       'gre' => 'GREConnector',
                       'stt' => 'STTConnector',
                       'bridge' => 'BridgeConnector',
                       'ipsec_gre' => 'IPsecGREConnector',
                       'ipsec_stt' => 'IPsecSTTConnector'
    }
    query = {
	  'display_name' => @resource[:display_name],
	  'credential' => {
	    'client_certificate' => {
	      'pem_encoded' => cert
	    },
	    'type' => 'SecurityCertificateCredential'
	  },
	  'transport_connectors' => [
	    {
	      'transport_zone_uuid' => @resource[:transport_zone_uuid],
	      'ip_address' => bridge_ip,
	      'type' => connector_mapping[@resource[:connector_type]]
	    }
	  ],
	  'integration_bridge_id' => @resource[:integration_bridge]
    }
    resp, data = @conn.post('/ws.v1/transport-node', query.to_json, { 'Cookie' => @cookie , 'Content-Type' => 'application/json'})
  end

  def destroy
    uuid = get_uuid
    unless uuid.nil?
      @conn.delete("/ws.v1/transport-node/#{uuid}", { 'Cookie' => @cookie})
    end
  end
end
