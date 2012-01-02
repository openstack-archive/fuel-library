require 'spec_helper'

describe 'keystone' do

  let :default_params do
    {
      'package_ensure'  => 'present',
      'log_verbose'     => 'False',
      'log_debug'       => 'False',
      'default_store'   => 'sqlite',
      'bind_host'       => '0.0.0.0',
      'bind_port'       => '5000',
      'admin_bind_host' => '0.0.0.0',
      'admin_bind_port' => '5001'
    }
  end

  [{},
   {
      'package_ensure'  => 'latest',
      'log_verbose'     => 'True',
      'log_debug'       => 'True',
      'default_store'   => 'ldap',
      'bind_host'       => '127.0.0.1',
      'bind_port'       => '50000',
      'admin_bind_host' => '127.0.0.1',
      'admin_bind_port' => '50001'
    }
  ].each do |param_set|

    describe "when #{param_set == {} ? "using default" : "specifying"} class parameters" do
      let :param_hash do
        param_set == {} ? default_params : param_set
      end

      let :params do
        param_set
      end

      it { should contain_package('keystone').with_ensure(param_hash['package_ensure']) }

      it { should contain_file('/etc/keystone').with(
        'ensure'     => 'directory',
        'owner'      => 'keystone',
        'group'      => 'keystone',
        'mode'       => '0755',
        'require'    => 'Package[keystone]'
      ) }

      # maybe keystone should always be with the API server?
      it 'should refresh nova-api if they are on the same machine'

      it { should contain_service('keystone').with(
        'ensure'     => 'running',
        'enable'     => 'true',
        'hasstatus'  => 'true',
        'hasrestart' => 'true'
      ) }

      it 'should compile the template based on the class parameters' do
        content = param_value(subject, 'file', 'keystone.conf', 'content')
        expected_lines = [
          "verbose = #{param_hash['log_verbose']}",
          "debug = #{param_hash['log_debug']}",
          "default_store = #{param_hash['default_store']}",
          "service_host = #{param_hash['bind_host']}",
          "service_port = #{param_hash['bind_port']}",
          "admin_host = #{param_hash['admin_bind_host']}",
          "admin_port = #{param_hash['admin_bind_port']}"
        ]
        (content.split("\n") & expected_lines).should == expected_lines
      end
    end
  end
end
