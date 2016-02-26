require 'net/http'
require 'json'

def handle_request(req, url)
  begin

    use_ssl = url.scheme == 'https' ? true : false
    r = Net::HTTP.start(url.hostname, url.port, ':use_ssl' => use_ssl) do |http|
      http.request(req)
    end

    if res.code != '200'
      raise "Received error response from Keystone server at #{url}: \
        #{res.message}"
    end

  rescue Errno::ECONNREFUSED => detail
    raise "Failed to connect to Keystone server at #{url}: #{detail}"
  rescue SocketError => detail
    raise "Failed to connect to Keystone server at #{url}: #{detail}"
  end

  r
end

def keystone_v2_authenticate(auth_url,
                             username,
                             password,
                             tenant_name)

  post_args = {
    'auth' => {
      'passwordCredentials' => {
        'username' => username,
        'password' => password,
        'tenantName' => tenant_name
      }
    }
  }

  url = URI.parse("#{auth_url}/tokens")
  req = Net::HTTP::Post.new url.path
  req['content-type'] = 'application/json'
  req.body = post_args.to_json

  res = handle_request(req, url)
  data = JSON.parse res.body
  [data['access']['token']['id'], data]
end

class Hiera
  module Backend
    class NailgunBackend
      # TODO: refact cache
      def initialize(_cache = nil)
        @nailgun_config = Config[:nailgun]
        @keystone_config = Config[:keystone]

        Hiera.debug('Hiera nailgun backend starting')

        @keystone_url = @keystone_config[:endpoint] + '/' \
          + @keystone_config[:api]

        @authtoken = keystone_v2_authenticate(
          @keystone_url,
          @keystone_config[:credentials][:user],
          @keystone_config[:credentials][:pass],
          @keystone_config[:credentials][:tenant])[0]

        @nailgun_url = @nailgun_config[:endpoint] + '/api/' \
          + @nailgun_config[:api]

        @cache = @cluster_id = @node_id = nil
      end

      def lookup(key, scope, _order_override, _resolution_type)
        if @node_id.nil?
          (@node_id, @cluster_id) = nailgun_node_id(scope['fqdn'])
          raise 'Failed to lookup node in nailgun' if @node_id.nil?
          Hiera.debug("Nailgun node id #{@node_id}, cluster: #{@cluster_id}")
        end

        if @cache.nil?
          Hiera.debug("Lookup #{key} from nailgun")
          return nailgun_api_request(key)
        else
          Hiera.debug("Lookup #{key} from cache")
          return @cache[key]
        end
      end

      private

      # TODO single nailgun request method
      def nailgun_node_id(fqdn)
        url = URI.parse(@nailgun_url + '/nodes')
        req = Net::HTTP::Get.new url.to_s
        req['X-Auth-Token'] = @authtoken
        res = handle_request(req, url)
        data = JSON.parse res.body
        data.each do |node|
          return node['id'], node['cluster'] if node['fqdn'] == fqdn
        end
        [nil, nil]
      end

      def nailgun_api_request(key)
        url = URI.parse(@nailgun_url + '/clusters/' + @cluster_id.to_s + \
          '/orchestrator/deployment/defaults/?nodes=' + @node_id.to_s)
        req = Net::HTTP::Get.new url.to_s
        req['X-Auth-Token'] = @authtoken
        res = handle_request(req, url)
        data = JSON.parse res.body
        @cache = data[0]
        data[0][key]
      end
    end
  end
end
