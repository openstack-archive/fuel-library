require 'spec_helper'

describe 'glance::api' do

  let :facts do
    {
      :osfamily => 'Debian'
    }
  end

  let :default_params do
    {
      :log_verbose   => 'False',
      :log_debug     => 'False',
      :bind_host     => '0.0.0.0',
      :bind_port     => '9292',
      :registry_host => '0.0.0.0',
      :registry_port => '9191',
      :log_file      => '/var/log/glance/api.log',
      :auth_type     => 'keystone'
    }
  end

  [{},
   {
      :log_verbose   => 'true',
      :log_debug     => 'true',
      :bind_host     => '127.0.0.1',
      :bind_port     => '9222',
      :registry_host => '127.0.0.1',
      :registry_port => '9111',
      :log_file      => '/var/log/glance-api.log',
      :auth_type     => 'not_keystone'
    }
  ].each do |param_set|

    describe "when #{param_set == {} ? "using default" : "specifying"} class parameters" do

      let :param_hash do
        default_params.merge(param_set)
      end

      let :params do
        param_set
      end

      it { should contain_class 'glance' }

      it { should contain_service('glance-api').with(
        'ensure'     => 'running',
        'hasstatus'  => 'true',
        'hasrestart' => 'true',
        'subscribe' => 'Concat[/etc/glance/glance-api.conf]'
      ) }

      it 'should compile the template based on the class parameters' do
        verify_contents(
          subject,
          '/var/lib/puppet/concat/_etc_glance_glance-api.conf/fragments/01_header',
          [
            "verbose = #{param_hash[:log_verbose]}",
            "debug = #{param_hash[:log_debug]}",
            "bind_host = #{param_hash[:bind_host]}",
            "bind_port = #{param_hash[:bind_port]}",
            "log_file = #{param_hash[:log_file]}",
            "registry_host = #{param_hash[:registry_host]}",
            "registry_port = #{param_hash[:registry_port]}",
          ]
        )
      end
      it 'should add paste deploy footers' do
        expected_lines = ['[paste_deploy]', 'flavor = keystone'] if params[:auth_type] = 'keystone'
        verify_contents(
          subject,
          '/var/lib/puppet/concat/_etc_glance_glance-api.conf/fragments/99_footer',
          expected_lines
        )

      end
    end
  end
end
