require 'spec_helper_system'

describe 'mongodb::server: with 10gen repo' do

  case node.facts['osfamily']
  when 'RedHat'
    package_name = 'mongo-10gen-server'
    service_name = 'mongod'
    config_file  = '/etc/mongod.conf'
  when 'Debian'
    package_name = 'mongodb-10gen'
    service_name = 'mongodb'
    config_file  = '/etc/mongodb.conf'
  end

  client_name  = 'mongo --version'

  context 'default parameters' do
    it 'should work with no errors' do
      case node.facts['osfamily']
      when 'RedHat'
        pp = <<-EOS
          class { 'mongodb::globals': manage_package_repo => true }->
          class { 'mongodb::server': }->
          class { 'mongodb::client': }
        EOS
      when 'Debian'
        pp = <<-EOS
          class { 'mongodb::globals': manage_package_repo => true }->
          class { 'mongodb::server': }
        EOS
      end

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

    describe command(client_name) do
      it do
        should return_exit_status 0
      end
    end
  end

  context 'test using custom port' do
    it 'change port to 27018' do
      pp = <<-EOS
        class { 'mongodb::globals': manage_package_repo => true }->
        class { 'mongodb::server': port => 27018 }
      EOS

      puppet_apply(pp) do |r|
         r.exit_code.should == 2
      end
    end

    describe port(27018) do
      sleep(20)
      it { should be_listening }
    end
  end

  context 'test shutdown of custom port' do
    it 'shut down service on port 27018' do
      pp = <<-EOS
        class {'mongodb::globals': manage_package_repo => true}->
        class {'mongodb::server': port => 27018, ensure => false}
      EOS

      puppet_apply(pp) do |r|
        r.exit_code.should == 2
      end
    end

    describe port(27018) do
      it { should_not be_listening}
    end

  end

  describe 'cleanup' do
     it 'uninstalls mongodb' do
       puppet_apply("class {'mongodb::globals': manage_package_repo => true }-> class { 'mongodb::server': ensure => false }-> class { 'mongodb::client': ensure => false}") do |r|
         r.exit_code.should_not == 1
       end
     end
  end
end
