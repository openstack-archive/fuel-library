require 'spec_helper'

describe 'cluster::rabbitmq_ocf' do

  shared_examples_for 'rabbitmq_ocf configuration' do

    let(:pre_condition) {
      'include rabbitmq::service'
    }
    let(:params) {{
      :primitive_type          => 'rabbitmq-server',
      :service_name            => 'rabbitmq-server',
      :port                    => '5672',
      :host_ip                 => '127.0.0.1',
      :debug                   => false,
      :ocf_script_file         => 'cluster/ocf/rabbitmq',
      :command_timeout         => '',
      :erlang_cookie           => 'EOKOWXQREETZSHFNTPEY',
      :admin_user              => 'nil',
      :admin_pass              => 'nil',
      :enable_rpc_ha           => false,
      :enable_notifications_ha => true,
      :fqdn_prefix             => 'nil',
      :pid_file                => 'nil',
      :policy_file             => 'nil',
      :start_timeout           => '120',
      :stop_timeout            => '120',
      :mon_timeout             => '120',
      :promote_timeout         => '120',
      :demote_timeout          => '120',
      :notify_timeout          => '120',
      :slave_mon_interval      => '30',
      :master_mon_interval     => '27',
      :mon_interval            => '35',
    }}

    let(:metadata) {{
      'migration-threshold' => '10',
      'failure-timeout'     => '30s',
      'resource-stickiness' => '100',
    }}

    let(:complex_metadata) {{
      'notify'          => 'true',
      'ordered'         => 'false',
      'interleave'      => 'true',
      'master-max'      => '1',
      'master-node-max' => '1',
      'target-role'     => 'Master',
      'requires'        => 'nothing'
    }}

    let(:monitor) {{
      'interval' => params[:mon_interval],
      'timeout'  => params[:mon_timeout]
    }}

    let(:monitor_master) {{
      'role'     => 'Master',
      'interval' => params[:master_mon_interval],
      'timeout'  => params[:mon_timeout]
    }}

    let(:monitor_slave) {{
      'role'            => 'Slave',
      'interval'        => params[:slave_mon_interval],
      'timeout'         => params[:mon_timeout],
      'OCF_CHECK_LEVEL' => '30'
    }}

    let(:start) {{
      'interval' => '0',
      'timeout'  => params[:start_timeout]
    }}

    let(:stop) {{
      'interval' => '0',
      'timeout'  => params[:stop_timeout]
    }}

    let(:promote) {{
      'interval' => '0',
      'timeout'  => params[:promote_timeout]
    }}

    let(:demote) {{
      'interval' => '0',
      'timeout'  => params[:demote_timeout]
    }}

    let(:notify) {{
      'interval' => '0',
      'timeout'  => params[:notify_timeout]
    }}

    let(:operations) {{
      'monitor'        => monitor,
      'monitor:Master' => monitor_master,
      'monitor:Slave'  => monitor_slave,
      'start'          => start,
      'stop'           => stop,
      'promote'        => promote,
      'demote'         => demote,
      'notify'        => notify,
    }}

    let(:parameters) {{
      'host_ip'                  => params[:host_ip],
      'node_port'                => params[:port],
      'debug'                    => params[:debug],
      'command_timeout'          => params[:command_timeout],
      'erlang_cookie'            => params[:erlang_cookie],
      'admin_user'               => params[:admin_user],
      'admin_password'           => params[:admin_pass],
      'enable_rpc_ha'            => params[:enable_rpc_ha],
      'enable_notifications_ha'  => params[:enable_notifications_ha],
      'fqdn_prefix'              => params[:fqdn_prefix],
      'pid_file'                 => params[:pid_file],
      'policy_file'              => params[:policy_file],
    }}

    it 'configures with the default params' do
      should contain_class('cluster::rabbitmq_ocf')
      should contain_pacemaker__service(params[:service_name]).with(
        :primitive_type   => params[:primitive_type],
        :complex_type     => 'master',
        :complex_metadata => complex_metadata,
        :metadata         => metadata,
        :operations       => operations,
        :parameters       => parameters
      )
    end
  end

  on_supported_os(supported_os: supported_os).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts.merge(common_facts) }

      let :packages do
        if facts[:osfamily] == 'Debian'
          [ 'crmsh', 'pcs' ]
        else
          ['crmsh']
        end
      end

      it_configures 'rabbitmq_ocf configuration'
    end
  end

end

