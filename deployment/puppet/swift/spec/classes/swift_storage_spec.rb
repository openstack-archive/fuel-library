require 'spec_helper'

describe 'swift::storage' do

  let :pre_condition do
    "class { 'swift': swift_hash_suffix => 'changeme' }
     include ssh::server::install
    "
  end

  let :default_params do
    {
      :package_ensure => 'present'
    }
  end

  [{},
   {
      :package_ensure => 'latest'
    }
  ].each do |param_set|

    describe "when #{param_set == {} ? "using default" : "specifying"} class parameters" do
      let :param_hash do
        default_params.merge(param_set)
      end

      let :params do
        param_set
      end

      ['xfsprogs', 'parted', 'rsync'].each do |present_package|
        it { should contain_package(present_package).with_ensure('present') }
      end
      #it 'should compile the template based on the class parameters' do
      #  content = param_value(subject, 'file', '/etc/glance/glance-api.conf', 'content')
      #  expected_lines = [
      #    "verbose = #{param_hash[:log_verbose]}",
      #    "debug = #{param_hash[:log_debug]}",
      #    "default_store = #{param_hash[:default_store]}",
      #    "bind_host = #{param_hash[:bind_host]}",
      #    "bind_port = #{param_hash[:bind_port]}",
      #    "registry_host = #{param_hash[:registry_host]}",
      #    "registry_port = #{param_hash[:registry_port]}",
      #    "log_file = #{param_hash[:log_file]}",
      #    "filesystem_store_datadir = #{param_hash[:filesystem_store_datadir]}",
      #    "swift_store_auth_address = #{param_hash[:swift_store_auth_address]}",
      #    "swift_store_user = #{param_hash[:swift_store_user]}",
      #    "swift_store_key = #{param_hash[:swift_store_key]}",
      #    "swift_store_container = #{param_hash[:swift_store_container]}",
      #    "swift_store_create_container_on_put = #{param_hash[:swift_store_create_container_on_put]}"
      #  ]
      #  (content.split("\n") & expected_lines).should == expected_lines
      #end
    end
  end
end
