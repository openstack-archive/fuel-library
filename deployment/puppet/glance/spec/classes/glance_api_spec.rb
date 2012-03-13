require 'spec_helper'

describe 'glance::api' do

  let :default_params do
    {
      :log_verbose => 'false',
      :log_debug => 'false',
      :default_store => 'file',
      :bind_host => '0.0.0.0',
      :bind_port => '9292',
      :registry_host => '0.0.0.0',
      :registry_port => '9191',
      :log_file => '/var/log/glance/api.log',
      :filesystem_store_datadir => '/var/lib/glance/images/',
      :swift_store_auth_address => '127.0.0.1:8080/v1.0/',
      :swift_store_user => 'jdoe',
      :swift_store_key => 'a86850deb2742ec3cb41518e26aa2d89',
      :swift_store_container => 'glance',
      :swift_store_create_container_on_put => 'False'
    }
  end

  [{},
   {
      :log_verbose => 'true',
      :log_debug => 'true',
      :default_store => 'file',
      :bind_host => '127.0.0.1',
      :bind_port => '9222',
      :registry_host => '127.0.0.1',
      :registry_port => '9111',
      :log_file => '/var/log/glance-api.log',
      :filesystem_store_datadir => '/var/lib/glance-images/',
      :swift_store_auth_address => '127.0.0.1:8080/v1.1/',
      :swift_store_user => 'dan',
      :swift_store_key => 'a',
      :swift_store_container => 'other',
      :swift_store_create_container_on_put => 'True'
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

      it do should contain_service('glance-api').with(
        'ensure'     => 'running',
        'hasstatus'  => 'true',
        'hasrestart' => 'true',
        'subscribe'  => 'File[/etc/glance/glance-api.conf]'
      ) end

      it 'should compile the template based on the class parameters' do
        content = param_value(subject, 'file', '/etc/glance/glance-api.conf', 'content')
        expected_lines = [
          "verbose = #{param_hash[:log_verbose]}",
          "debug = #{param_hash[:log_debug]}",
          "default_store = #{param_hash[:default_store]}",
          "bind_host = #{param_hash[:bind_host]}",
          "bind_port = #{param_hash[:bind_port]}",
          "registry_host = #{param_hash[:registry_host]}",
          "registry_port = #{param_hash[:registry_port]}",
          "log_file = #{param_hash[:log_file]}",
          "filesystem_store_datadir = #{param_hash[:filesystem_store_datadir]}",
          "swift_store_auth_address = #{param_hash[:swift_store_auth_address]}",
          "swift_store_user = #{param_hash[:swift_store_user]}",
          "swift_store_key = #{param_hash[:swift_store_key]}",
          "swift_store_container = #{param_hash[:swift_store_container]}",
          "swift_store_create_container_on_put = #{param_hash[:swift_store_create_container_on_put]}"
        ]
        (content.split("\n") & expected_lines).should == expected_lines
      end
    end
  end
end
