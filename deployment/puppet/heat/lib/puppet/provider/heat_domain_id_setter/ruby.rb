## NB: This must work with Ruby 1.8!

# This provider permits the stack_user_domain parameter in heat.conf
# to be set by providing a domain_name to the Puppet module and
# using the Keystone REST API to translate the name into the corresponding
# UUID.
#
# This requires that tenant names be unique.  If there are multiple matches
# for a given tenant name, this provider will raise an exception.

require 'rubygems'
require 'net/http'
require 'json'

class KeystoneError < Puppet::Error
end

class KeystoneConnectionError < KeystoneError
end

class KeystoneAPIError < KeystoneError
end

# Provides common request handling semantics to the other methods in
# this module.
#
# +req+::
#   An HTTPRequest object
# +url+::
#   A parsed URL (returned from URI.parse)
def handle_request(req, url)
    begin
        # There is issue with ipv6 where address has to be in brackets, this causes the
        # underlying ruby TCPSocket to fail. Net::HTTP.new will fail without brackets on
        # joining the ipv6 address with :port or passing brackets to TCPSocket. It was
        # found that if we use Net::HTTP.start with url.hostname the incriminated code
        # won't be hit.
        use_ssl = url.scheme == "https" ? true : false
        res = Net::HTTP.start(url.hostname, url.port, {:use_ssl => use_ssl}) {|http|
            http.request(req)
        }

        if res.code != '200'
            raise KeystoneAPIError, "Received error response from Keystone server at #{url}: #{res.message}"
        end
    rescue Errno::ECONNREFUSED => detail
        raise KeystoneConnectionError, "Failed to connect to Keystone server at #{url}: #{detail}"
    rescue SocketError => detail
        raise KeystoneConnectionError, "Failed to connect to Keystone server at #{url}: #{detail}"
    end

    res
end

# Authenticates to a Keystone server and obtains an authentication token.
# It returns a 2-element +[token, authinfo]+, where +token+ is a token
# suitable for passing to openstack apis in the +X-Auth-Token+ header, and
# +authinfo+ is the complete response from Keystone, including the service
# catalog (if available).
#
# +auth_url+::
#   Keystone endpoint URL.  This function assumes API version
#   2.0 and an administrative endpoint, so this will typically look like
#   +http://somehost:35357/v2.0+.
#
# +username+::
#   Username for authentication.
#
# +password+::
#   Password for authentication
#
# +tenantID+::
#   Tenant UUID
#
# +tenantName+::
#   Tenant name
#
def heat_handle_requests(auth_url,
                             username,
                             password,
                             tenantId=nil,
                             tenantName=nil)

    post_args = {
        'auth' => {
            'passwordCredentials' => {
                'username' => username,
                'password' => password
            },
        }}

    if tenantId
        post_args['auth']['tenantId'] = tenantId
    end

    if tenantName
        post_args['auth']['tenantName'] = tenantName
    end

    url = URI.parse("#{auth_url}/tokens")
    req = Net::HTTP::Post.new url.path
    req['content-type'] = 'application/json'
    req.body = post_args.to_json

    res = handle_request(req, url)
    data = JSON.parse res.body
    return data['access']['token']['id'], data
end

# Queries a Keystone server to a list of all tenants.
#
# +auth_url+::
#   Keystone endpoint.  See the notes for +auth_url+ in
#   +heat_handle_requests+.
#
# +token+::
#   A Keystone token that will be passed in requests as the value of the
#   +X-Auth-Token+ header.
#
def keystone_v3_domains(auth_url,
                        token)

    auth_url.sub!('v2.0', 'v3')
    url = URI.parse("#{auth_url}/domains")
    req = Net::HTTP::Get.new url.path
    req['content-type'] = 'application/json'
    req['x-auth-token'] = token

    res = handle_request(req, url)
    data = JSON.parse res.body
    data['domains']
end

Puppet::Type.type(:heat_domain_id_setter).provide(:ruby) do
    def authenticate
        token, authinfo = heat_handle_requests(
            @resource[:auth_url],
            @resource[:auth_username],
            @resource[:auth_password],
            nil,
            @resource[:auth_tenant_name])

        return token
    end

    def find_domain_by_name(token)
        domains = keystone_v3_domains(
            @resource[:auth_url],
            token)
        domains.select{|domain| domain['name'] == @resource[:domain_name]}
    end

    def exists?
        false
    end

    def create
        config
    end

    # This looks for the domain specified by the 'domain_name' parameter to
    # the resource and returns the corresponding UUID if there is a single
    # match.
    #
    # Raises a KeystoneAPIError if:
    #
    # - There are multiple matches, or
    # - There are zero matches
    def get_domain_id
        token = authenticate
        domains = find_domain_by_name(token)

        if domains.length == 1
            return domains[0]['id']
        elsif domains.length > 1
            name = domains[0]['name']
            raise KeystoneAPIError, 'Found multiple matches for domain name "#{name}"'
        else
            raise KeystoneAPIError, 'Unable to find matching domain'
        end
    end

    def config
        Puppet::Type.type(:heat_config).new(
            {:name => 'DEFAULT/stack_user_domain', :value => "#{get_domain_id}"}
        ).create
    end

end
