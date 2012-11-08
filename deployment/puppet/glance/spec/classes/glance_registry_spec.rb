require 'spec_helper'

describe 'glance::registry' do

  let :facts do
    {
      :osfamily => 'Debian'
    }
  end

  let :default_params do
    {
      :log_verbose      => 'False',
      :log_debug        => 'False',
      :bind_host        => '0.0.0.0',
      :bind_port        => '9191',
      :log_file         => '/var/log/glance/registry.log',
      :sql_connection   => 'sqlite:///var/lib/glance/glance.sqlite',
      :sql_idle_timeout => '3600',
      :enabled          => true
    }
  end

  [
    {},
    {
      :log_verbose => 'true',
      :log_debug => 'true',
      :bind_host => '127.0.0.1',
      :bind_port => '9111',
      :log_file => '/var/log/glance-registry.log',
      :sql_connection => 'sqlite:///var/lib/glance.sqlite',
      :sql_idle_timeout => '360',
      :enabled          => false
    }
  ].each do |param_set|

    describe "when #{param_set == {} ? "using default" : "specifying"} class parameters" do
      let :param_hash do
        param_set == {} ? default_params : params
      end

      let :params do
        param_set
      end

      it { should contain_class 'glance::registry' }

      it { should contain_service('glance-registry').with(
          'ensure'     => param_hash[:enabled] ? 'running' : 'stopped',
          'enable'     => param_hash[:enabled],
          'hasstatus'  => 'true',
          'hasrestart' => 'true',
          'subscribe'  => 'File[/etc/glance/glance-registry.conf]',
          'require'    => 'Class[Glance]'
      )}

      it 'should only sync the db if the service is enabled' do

        if param_hash[:enabled]
          should contain_exec('glance-manage db_sync').with(
            'path'        => '/usr/bin',
            'refreshonly' => true,
            'logoutput'   => 'on_failure',
            'subscribe'   => ['Package[glance]', 'File[/etc/glance/glance-registry.conf]'],
            'notify'      => 'Service[glance-registry]'
          )
        end
      end

      it 'should compile the template based on the class parameters' do
        content = param_value(subject, 'file', '/etc/glance/glance-registry.conf', 'content')
        expected_lines = [
          "verbose = #{param_hash[:log_verbose]}",
          "debug = #{param_hash[:log_debug]}",
          "bind_host = #{param_hash[:bind_host]}",
          "bind_port = #{param_hash[:bind_port]}",
          "log_file = #{param_hash[:log_file]}",
          "sql_connection = #{param_hash[:sql_connection]}",
          "sql_idle_timeout = #{param_hash[:sql_idle_timeout]}"
        ]
        (content.split("\n") & expected_lines).should == expected_lines
      end
    end
  end
end
