begin
require 'spec_helper_system'

describe 'mongodb::server:' do

  case node.facts['osfamily']
  when 'RedHat'
    package_name = 'mongodb-server'
    service_name = 'mongod'
    config_file  = '/etc/mongodb.conf'
  when 'Debian'
    package_name = 'mongodb-server'
    service_name = 'mongodb'
    config_file  = '/etc/mongodb.conf'
  end

  context 'default parameters' do
    it 'should work with no errors' do
      pp = <<-EOS
        class { 'mongodb::server': }
      EOS

      puppet_apply(pp) do |r|
        r.exit_code.should == 2
        r.refresh
        r.exit_code.should == 0
      end
    end

    describe package(package_name) do
      it { should be_installed }
    end

    describe file(config_file) do
      it { should be_file }
    end

    describe service(service_name) do
       it { should be_enabled }
       it { should be_running }
    end

    describe port(27017) do
      it do
        sleep(20)
        should be_listening
      end
    end
  end

  context 'test using custom port' do
    it 'change port to 27018' do
      pp = <<-EOS
        class { 'mongodb::server': port => 27018 }
      EOS

      puppet_apply(pp) do |r|
         r.exit_code.should == 2
         r.refresh
         r.exit_code.should == 0
      end
    end

    describe port(27018) do
      it { should be_listening }
    end

  end
end

end
