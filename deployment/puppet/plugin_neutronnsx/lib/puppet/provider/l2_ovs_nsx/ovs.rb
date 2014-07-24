require 'net/https'
require 'rubygems'
require 'json'

Puppet::Type.type(:l2_ovs_nsx).provide(:ovs) do

  commands :vsctl => '/usr/bin/ovs-vsctl'
  commands :vspki => '/usr/bin/ovs-pki'

  def generate_cert
    Puppet.debug "Generating certificate to connect OVS to NSX"
    @cert_dir = "/etc/openvswitch"
    @cert_path = "#{@cert_dir}/ovsclient-cert.pem"
    @privkey_path = "#{@cert_dir}/ovsclient-privkey.pem"
    @cacert_path = "#{@cert_dir}/vswitchd.cacert"
    vsctl("set-manager", "ssl:#{@resource[:nsx_endpoint].split(',')[0].strip}")
    if not File.exists? @cert_path
      Puppet.debug "Certificate '#{@cert_path} is not exist. Generating new one"
      old_dir = Dir.pwd
      Dir.chdir @cert_dir
      vspki("init", "--force")
      vspki("req+sign", "ovsclient", "controller")
      vsctl("--", "--bootstrap", "set-ssl", "#{@privkey_path}", "#{@cert_path}", "#{@cacert_path}")
      Dir.chdir old_dir
    end
    Puppet.debug "Ceritficate is ready to use"
  end

  def get_cert
    Puppet.debug "Getting certificate '#{@cert_path}'"
    if File.exists? @cert_path
      cert_file = File.open(@cert_path, "r")
      cert_contents = cert_file.read
      cert = cert_contents.gsub(/.*?(?=-*BEGIN CERTIFICATE-*)/m, "")
      Puppet.debug "Certificate is found"
      return cert
    end
    Puppet.debug "Certificate '#{@cert_path} is not exist. Return nothing"
    return nil
  end

  def login
    Puppet.debug "Trying to login to NSX Controller API"
    Puppet.debug "NSX controller endpoint is '@resource[:nsx_endpoint].split(',')[0]'"
    conn = Net::HTTP.new(@resource[:nsx_endpoint].split(',')[0],443)
    conn.use_ssl = true
    conn.verify_mode = OpenSSL::SSL::VERIFY_NONE
    resp, data = conn.post('/ws.v1/login', "username=#{@resource[:nsx_username]}&password=#{@resource[:nsx_password]}", {'Content-Type' => 'application/x-www-form-urlencoded'})
    cookie = resp.response['set-cookie'].split('; ')[0]
    Puppet.debug "Connection established, Cookie gathered. Logged in successfully"
    return conn, cookie
  end

  def get_uuid
    Puppet.debug "Getting UUID of Tansport node '#{@resource[:display_name]}'"
    resp, data = @conn.get('/ws.v1/transport-node', { 'Cookie' => @cookie })
    nodes = JSON.load(data)['results']
    Puppet.debug "Gathered #{nodes.size} transport nodes"
    Puppet.debug "HREFs to the nodes are: #{nodes.map{|n|n['_href']}.join(', ')}"
    nodes.each { |node|
      Puppet.debug "Processing node with HREF #{node['_href']}"
      resp, data = @conn.get(node['_href'], { 'Cookie' => @cookie })
      node_data = JSON.load(data)
      Puppet.debug "Display_name of the node is #{node_data['display_name']}"
      if node_data['display_name'] == @resource[:display_name]
        Puppet.debug "Transport node '#{@resource[:display_name]}' found. Returning UUID #{node_data['uuid']}"
        return node_data['uuid']
      end
    }
    Puppet.debug "Transport node '#{@resource[:display_name]}' not found"
    return nil
  end

  def exists?
    Puppet.debug "Is L2_OVS_NSX connection exist?"
    @conn, @cookie = login
    query_result = get_uuid
    unless query_result.nil?
      return true
    end
    return false
  end

  def create
    Puppet.debug "Creating OVS connection to NSX controller"
    generate_cert
    cert = get_cert
    bridge_ip = @resource[:ip_address].split("/")[0]
    # VxLAN is not supported now (07/2014)
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
    Puppet.debug "New Transport node registered in NSX"
  end

  def destroy
    Puppet.debug "Destroying Transport node"
    uuid = get_uuid
    unless uuid.nil?
      @conn.delete("/ws.v1/transport-node/#{uuid}", { 'Cookie' => @cookie})
      Puppet.debug "Transport node with UUID '#{uuid}' has been destroyed"
    end
  end
end
