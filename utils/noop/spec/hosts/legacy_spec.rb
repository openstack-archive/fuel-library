require 'spec_helper'
manifest = 'legacy.pp'
manifest_dir = '/etc/puppet/modules/osnailyfacter/modular'

astute_filename = Noop.astute_yaml_name
settings = YAML.load_file(Noop.astute_yaml_path)
node = settings['fqdn']

# Check if this task is enabled for the astute.yaml
if settings['tasks'].map { |n| n['parameters']['puppet_manifest'] }.include?("#{manifest_dir}/#{manifest}")
  describe manifest do
    let :facts do
      Noop.facts
    end

    before :all do
      Noop.set_manifest manifest
    end

    ########################################
    # Tests for node as a shared example
    shared_examples "puppet catalogue" do
      it { should compile }
    end

    #######################################
    # Testing on different operating systems
    # Ubuntu
    context 'on Ubuntu platforms' do
      before do
        Noop.facts.merge!( :osfamily => 'Debian' )
        Noop.facts.merge!( :lsbdistid => 'Ubuntu' )
        Noop.facts.merge!( :operatingsystem => 'Ubuntu' )
        Noop.facts.merge!( :operatingsystemrelease => '12.04' )
      end
      it_behaves_like "puppet catalogue"
    end

    # CentOS
    context 'on CentOS platforms' do
      before do
        Noop.facts.merge!( :osfamily => 'RedHat' )
        Noop.facts.merge!( :lsbdistid => 'CentOS' )
        Noop.facts.merge!( :operatingsystem => 'CentOS' )
        Noop.facts.merge!( :operatingsystemrelease => '6.5' )
      end
      it_behaves_like "puppet catalogue"
    end

  end
end
