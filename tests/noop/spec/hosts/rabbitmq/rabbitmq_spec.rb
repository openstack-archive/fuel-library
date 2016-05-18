# ROLE: primary-controller
# ROLE: controller

require 'spec_helper'
require 'shared-examples'
manifest = 'rabbitmq/rabbitmq.pp'

describe manifest do

  before(:each) do
    Noop.puppet_function_load :is_pkg_installed
    MockFunction.new(:is_pkg_installed) do |function|
      allow(function).to receive(:call).and_return false
    end
  end

  shared_examples 'catalog' do
    before do
      $environment_variables = Noop.resource_parameter_value self, 'class',
        'rabbitmq', 'environment_variables'
      $config_kernel_variables = Noop.resource_parameter_value self, 'class',
        'rabbitmq', 'config_kernel_variables'
      $config_variables = Noop.resource_parameter_value self, 'class',
        'rabbitmq', 'config_variables'
      $config_management_variables = Noop.resource_parameter_value self, 'class',
        'rabbitmq', 'config_management_variables'
      case facts[:osfamily]
      when 'RedHat'
        $command_timeout  = "-s KILL"
        $package_provider = 'yum'
      when 'Debian'
        $command_timeout  = "--signal=KILL"
        $package_provider = 'apt'
      end
    end

    network_scheme = Noop.hiera_structure('network_scheme', {})
    let(:prepare) do
      Noop.puppet_function 'prepare_network_config', network_scheme
    end

    let(:rabbitmq_bind_ip_address) do
      prepare
      Noop.puppet_function 'get_network_role_property',
       'mgmt/messaging', 'ipaddr' || 'UNSET'
    end

    erlang_cookie = Noop.hiera('erlang_cookie', 'EOKOWXQREETZSHFNTPEY')
    version = Noop.hiera('rabbit_version', '3.3.5')
    amqp_port = Noop.hiera('amqp_port', '5673')
    workers_max = Noop.hiera 'workers_max'
    debug = Noop.hiera('debug', false)
    threads_max = 2*workers_max.to_i
    rabbit_hash = Noop.hiera_structure 'rabbit'
    use_pacemaker = rabbit_hash.fetch(['pacemaker'], true)
    pid_file = rabbit_hash.fetch('pid_file', '/var/run/rabbitmq/p_pid')
    file_limit = rabbit_hash.fetch('file_limits', 100000)
    enabled = rabbit_hash.fetch('enabled', true)
    management_bind_ip_address = Noop.hiera('management_bind_ip_address', '127.0.0.1')
    management_port = Noop.hiera('rabbit_management_port', '15672')
    enable_rpc_ha = Noop.hiera('enable_rpc_ha', 'false')
    enable_notifications_ha = Noop.hiera('enable_notifications_ha', 'true')
    fqdn_prefix = Noop.hiera('node_name_prefix_for_messaging', 'messaging-')
    rabbit_config_variables = Noop.hiera_hash('rabbit_config_variables', {})
    rabbit_ocf = Noop.hiera_hash('rabbit_ocf', {
      :start_timeout           => '180',
      :stop_timeout            => '120',
      :mon_timeout             => '180',
      :promote_timeout         => '120',
      :demote_timeout          => '120',
      :notify_timeout          => '180',
      :slave_mon_interval      => '30',
      :master_mon_interval     => '27',
      :mon_interval            => '35',
    })

    let (:params) do {
      :admin_enable                => false,
      :management_port             => management_port,
      :repos_ensure                => false,
      :package_provider            => $package_provider,
      :package_source              => nil,
      :service_ensure              => 'running',
      :service_manage              => true,
      :port                        => amqp_port,
      :delete_guest_user           => true,
      :default_user                => rabbit_hash['user'],
      :default_pass                => rabbit_hash['password'],
      :config_cluster              => false,
      :version                     => version,
      :node_ip_address             => rabbitmq_bind_ip_address,
      :config_kernel_variables     => $config_kernel_variables,
      :config_management_variables => $config_management_variables,
      :config_variables            => $config_variables.merge(rabbit_config_variables),
      :environment_variables       => $environment_variables,
      :file_limit                  => file_limit,
      :tcp_keepalive               => true, }
    end

    it 'has correct SERVER_ERL_ARGS in environment_variables' do
      expect($environment_variables['SERVER_ERL_ARGS']).to eq "\"+K true +A#{threads_max} +P 1048576\""
    end

    it 'has correct SERVER_ERL_ARGS in environment_variables on 4 CPU & 32G system' do
      expect($environment_variables['SERVER_ERL_ARGS']).to eq "\"+K true +A34 +P 1048576\""
    end

    it 'has correct ERL_EPMD_ADDRESS in environment_variables' do
      node_ip_address = Noop.puppet_function 'get_network_role_property', 'mgmt/messaging', 'ipaddr'
      expect($environment_variables['ERL_EPMD_ADDRESS']).to eq node_ip_address
    end

    it "should contain nodename" do
      fqdn_prefix = Noop.hiera('node_name_prefix_for_messaging', 'messaging-')
      node_name = "rabbit@#{fqdn_prefix}#{facts[:hostname]}"
      expect($environment_variables['NODENAME']).to eq node_name
    end

    it 'should configure rabbitmq class' do
      should contain_class('rabbitmq').with(
        :admin_enable                => params[:admin_enable],
        :management_port             => params[:management_port],
        :repos_ensure                => params[:repos_ensure],
        :package_provider            => params[:package_provider],
        :package_source              => params[:package_source],
        :service_ensure              => params[:service_ensure],
        :service_manage              => params[:service_manage],
        :port                        => params[:port],
        :delete_guest_user           => params[:delete_guest_user],
        :default_user                => params[:default_user],
        :default_pass                => params[:default_pass],
        :config_cluster              => params[:config_cluster],
        :version                     => params[:version],
        :node_ip_address             => params[:node_ip_address],
        :config_kernel_variables     => params[:config_kernel_variables],
        :config_management_variables => params[:config_management_variables],
        :config_variables            => params[:config_variables],
        :environment_variables       => params[:environment_variables],
        :file_limit                  => params[:file_limit],
        :tcp_keepalive               => params[:tcp_keepalive],
      )
    end

    it 'should configure rabbit fence class' do
      if use_pacemaker
        should contain_class('cluster::rabbitmq_fence').with(
          :enabled => enabled).that_requires('Class[rabbitmq]')
      end
    end

    it 'should configure rabbit for nova' do
      should contain_class('nova::rabbitmq').with(
        :enabled  => enabled,
        :userid   => rabbit_hash['user'],
        :password => rabbit_hash['password'],
      ).that_requires('Class[rabbitmq]')
    end

    it 'should configure pacemaker RA' do
      if use_pacemaker
        should contain_class('cluster::rabbitmq_ocf').with(
          :command_timeout         => $command_timeout,
          :debug                   => debug,
          :erlang_cookie           => erlang_cookie,
          :admin_user              => rabbit_hash['user'],
          :admin_pass              => rabbit_hash['password'],
          :host_ip                 => management_bind_ip_address,
          :enable_rpc_ha           => enable_rpc_ha,
          :enable_notifications_ha => enable_notifications_ha,
          :fqdn_prefix             => fqdn_prefix,
          :pid_file                => pid_file,
          :policy_file             => '/usr/sbin/set_rabbitmq_policy',
          :start_timeout           => rabbit_ocf[:start_timeout],
          :stop_timeout            => rabbit_ocf[:stop_timeout],
          :mon_timeout             => rabbit_ocf[:mon_timeout],
          :promote_timeout         => rabbit_ocf[:promote_timeout],
          :demote_timeout          => rabbit_ocf[:demote_timeout],
          :notify_timeout          => rabbit_ocf[:notify_timeout],
          :slave_mon_interval      => rabbit_ocf[:slave_mon_interval],
          :master_mon_interval     => rabbit_ocf[:master_mon_interval],
          :mon_interval            => rabbit_ocf[:mon_interval],
        ).that_comes_before('Class[nova::rabbitmq]')
        should contain_class('cluster::rabbitmq_ocf').that_requires(
          'Class[rabbitmq::install]')
      end
    end

    it "should contain rabbitmq correct log levels" do
      log_levels = sprintf('[{connection, %s}]', debug ? 'debug' : 'info')
      should contain_class('rabbitmq').with_config_variables(/#{log_levels}/)
    end

    it "should configure rabbitmq management" do
      collect_statistics_interval = '[{collect_statistics_interval,30000}]'
      rates_mode = '[{rates_mode, none}]'
      node_ip_address = Noop.puppet_function 'get_network_role_property', 'mgmt/messaging', 'ipaddr'
      listener = "[{port, #{management_port}}, {ip,\"#{node_ip_address}\"}]"
      should contain_class('rabbitmq').with_config_variables(/#{collect_statistics_interval}/)
      should contain_class('rabbitmq').with_config_management_variables(/#{rates_mode}/)
      should contain_class('rabbitmq').with_config_management_variables(/#{listener}/)
    end

    # Partial LP#1493520
    it "should configure rabbitmq disk_free_limit" do
      disk_free_limit = '[{disk_free_limit,5000000}]'
      should contain_class('rabbitmq').with_config_variables(/#{disk_free_limit}/)
    end

    it "should start epmd before rabbitmq plugins" do
      should contain_exec('epmd_daemon').that_comes_before('Rabbitmq_plugin[rabbitmq_management]')
    end

    it "should override service on package install" do
      should contain_tweaks__ubuntu_service_override('rabbitmq-server')
    end

  end
  test_ubuntu_and_centos manifest
end
