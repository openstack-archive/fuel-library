module OpenStack
  module Sahara
    class Cluster_Template

      attr_reader :id
      attr_reader :name
      attr_reader :hadoop_version
      attr_reader :plugin_name
      attr_reader :neutron_management_network
      attr_reader :description
      attr_reader :node_groups

      def initialize(ct_info)
        @id = ct_info['id']
        @name = ct_info['name']
        @hadoop_version = ct_info['hadoop_version']
        @neutron_management_network = ct_info['neutron_management_network']
        @description = ct_info['description']
        @node_groups = ct_info['node_groups']
        @plugin_name = ct_info['plugin_name']
      end

      def [](key)
        key = key.to_sym
        send key
      end

    end
  end
end

module OpenStack
  module Sahara
    class Node_Group_Template

      attr_reader :id
      attr_reader :name
      attr_reader :description
      attr_reader :plugin_name
      attr_reader :flavor_id
      attr_reader :node_processes
      attr_reader :hadoop_version
      attr_reader :floating_ip_pool
      attr_reader :auto_security_group

      def initialize(ngt_info)
        @id = ngt_info['id']
        @name = ngt_info['name']
        @description = ngt_info['description']
        @plugin_name = ngt_info['plugin_name']
        @flavor_id = ngt_info['flavor_id']
        @node_processes = ngt_info['node_processes']
        @hadoop_version = ngt_info['hadoop_version']
        @floating_ip_pool = ngt_info['floating_ip_pool']
        @auto_security_group = ngt_info['auto_security_group']
      end

      def [](key)
        key = key.to_sym
        send key
      end

    end
  end
end

module OpenStack
  module Sahara
    class Connection

      attr_accessor :connection

      def initialize(connection)
        @connection = connection
        OpenStack::Authentication.init(@connection)
      end

      def authok?
        connection.authok
      end

      #########################################################################

      def node_group_template_url(node_group_template_id = nil)
        url = '/node-group-templates'
        url += "/#{node_group_template_id}" if node_group_template_id
        url
      end

      def list_node_group_templates
        response = connection.req('GET', node_group_template_url)
        volumes_hash = JSON.parse(response.body)['node_group_templates']
        volumes_hash.inject([]) { |res, current| res << OpenStack::Sahara::Node_Group_Template.new(current); res }
      end

      def get_node_group_template(node_group_template_id)
        response = connection.req('GET', node_group_template_url(node_group_template_id))
        volume_hash = JSON.parse(response.body)['node_group_template']
        return unless volume_hash
        OpenStack::Sahara::Node_Group_Template.new volume_hash
      end

      def create_node_group_template(options)
        # check input data
        data = JSON.generate(options)
        response = connection.csreq('POST',
                                    connection.service_host,
                                    "#{connection.service_path}#{node_group_template_url}",
                                    connection.service_port,
                                    connection.service_scheme,
                                    {
                                        'content-type' => 'application/json',
                                    },
                                    data
        )
        OpenStack::Exception.raise_exception(response) unless response.code.match(/^20.$/)
        node_group_template_info = JSON.parse(response.body)['node_group_template']
        OpenStack::Volume::Volume.new node_group_template_info
      end

      def delete_node_group_template(node_group_template_id)
        connection.req('DELETE', node_group_template_url(node_group_template_id))
        true
      end

      #########################################################################

      def cluster_template_url(cluster_template_id = nil)
        url = '/cluster-templates'
        url += "/#{cluster_template_id}" if cluster_template_id
        url
      end

      def list_cluster_templates
        response = connection.req('GET', cluster_template_url)
        cluster_templates_hash = JSON.parse(response.body)['cluster_templates']
        cluster_templates_hash.inject([]) { |res, current| res << OpenStack::Sahara::Cluster_Template.new(current); res }
      end

      def get_cluster_template(cluster_template_id)
        response = connection.req('GET', cluster_template_url(cluster_template_id))
        cluster_template_hash = JSON.parse(response.body)['cluster_template']
        return unless cluster_template_hash
        OpenStack::Sahara::Cluster_Template.new cluster_template_hash
      end

      def create_cluster_template(options)
        # check input data
        data = JSON.generate(options)
        response = connection.csreq('POST',
                                    connection.service_host,
                                    "#{connection.service_path}#{cluster_template_url}",
                                    connection.service_port,
                                    connection.service_scheme,
                                    {
                                        'content-type' => 'application/json',
                                    },
                                    data
        )
        OpenStack::Exception.raise_exception(response) unless response.code.match(/^20.$/)
        cluster_template_info = JSON.parse(response.body)['cluster_template']
        OpenStack::Volume::Volume.new cluster_template_info
      end

      def delete_cluster_template(cluster_template_id)
        connection.req('DELETE', cluster_template_url(cluster_template_id))
        true
      end

    end

  end
end

module OpenStack
  class << Connection

    def create(options = {:retry_auth => true})
      #call private constructor and grab instance vars
      connection = new(options)
      case connection.service_type
        when 'compute'
          OpenStack::Compute::Connection.new(connection)
        when 'object-store'
          OpenStack::Swift::Connection.new(connection)
        when 'volume'
          OpenStack::Volume::Connection.new(connection)
        when 'image'
          OpenStack::Image::Connection.new(connection)
        when 'network'
          OpenStack::Network::Connection.new(connection)
        when 'data-processing'
          OpenStack::Sahara::Connection.new(connection)
        else
          raise Exception::InvalidArgument, "Invalid :service_type parameter: #{@service_type}"
      end
    end
  end
end

module OpenStack
  module Network
    class Router

      attr_reader :id
      attr_reader :name
      attr_reader :admin_state_up
      attr_reader :status
      attr_reader :external_gateway_info
      attr_reader :tenant_ip
      attr_reader :enable_snat
      attr_reader :admin_state_up

      def initialize(router_info={})
        @name = router_info['name']
        @status = router_info['status']
        @external_gateway_info = router_info['external_gateway_info']
        @admin_state_up = router_info['admin_state_up']
        @tenant_ip = router_info['tenant_ip']
        @id = router_info['id']
        @enable_snat = router_info['enable_snat']
      end
    end
  end
end

module OpenStack
  module Network
     class Network

      attr_reader :id
      attr_reader :name
      attr_reader :admin_state_up
      attr_reader :status
      attr_reader :subnets
      attr_reader :shared
      attr_reader :tenant_id

     def initialize(net_info={})
       @id = net_info["id"]
       @name = net_info["name"]
       @admin_state_up = net_info["admin_state_up"]
       @status = net_info["status"]
       @subnets = net_info["subnets"]
       @shared = net_info["shared"]
       @tenant_id = net_info["tenant_id"]
     end

    end

  end
end

module OpenStack
  class Connection

    def req(method, path, options = {})
      server   = options[:server]   || @service_host
      port     = options[:port]     || @service_port
      scheme   = options[:scheme]   || @service_scheme
      headers  = options[:headers]  || {'content-type' => 'application/json'}
      data     = options[:data]
      attempts = options[:attempts] || 0
      path = @service_path + @quantum_version.to_s + path
      res = csreq(method,server,path,port,scheme,headers,data,attempts)
      res.code.match(/^20.$/) ? (return res) : OpenStack::Exception.raise_exception(res)
    end

    def initialize(options = {:retry_auth => true})
      @retries = options[:retries] || 3
      @authuser = options[:username] || (raise Exception::MissingArgument, "Must supply a :username")
      @authkey = options[:api_key] || (raise Exception::MissingArgument, "Must supply an :api_key")
      @auth_url = options[:auth_url] || (raise Exception::MissingArgument, "Must supply an :auth_url")
      @authtenant = (options[:authtenant_id])? {:type => "tenantId", :value=>options[:authtenant_id]} : {:type=>"tenantName", :value=>(options[:authtenant_name] || options[:authtenant] || @authuser)}
      @auth_method = options[:auth_method] || "password"
      @service_name = options[:service_name] || nil
      @service_type = options[:service_type] || "compute"
      @region = options[:region] || @region = nil
      @regions_list = {} # this is populated during authentication - from the returned service catalogue
      @is_debug = options[:is_debug]
      auth_uri=nil
      begin
        auth_uri=URI.parse(@auth_url)
      rescue Exception => e
        raise Exception::InvalidArgument, "Invalid :auth_url parameter: #{e.message}"
      end
      raise Exception::InvalidArgument, "Invalid :auth_url parameter." if auth_uri.nil? or auth_uri.host.nil?
      @auth_host = auth_uri.host
      @auth_port = auth_uri.port
      @auth_scheme = auth_uri.scheme
      @auth_path = auth_uri.path
      @retry_auth = options[:retry_auth]
      @proxy_host = options[:proxy_host]
      @proxy_port = options[:proxy_port]
      @authok = false
      @http = {}
      @quantum_version = '/v2.0' if @service_type == 'network'
    end
  end
end

module OpenStack
  module Network
    class Connection
      def list_routers
        response = @connection.req('GET', '/routers')
        nets_hash = JSON.parse(response.body)['routers']
        nets_hash.inject([]){|res, current| res << OpenStack::Network::Router.new(current); res}
      end
      alias :routers :list_routers
    end
  end
end
