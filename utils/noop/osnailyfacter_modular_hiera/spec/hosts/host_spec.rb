require 'spec_helper'
require 'yaml'

astute_path = File.expand_path(File.join(__FILE__, '..', '..', '..', '..', 'astute.yaml'))
fixtures_path = File.expand_path(File.join(__FILE__, '..', 'fixtures'))
module_path = File.expand_path(File.join(__FILE__, '..', '..', '..', '..', '..', 'deployment', 'puppet'))

# Get astute_filename from ENV
astute_filename = ENV['astute_filename']

# Load settings from appropriate astute.yaml
astute_file = File.expand_path(File.join(astute_path, astute_filename))
puts astute_file
settings = YAML.load_file(astute_file)
node = settings['fqdn']
test_yaml = astute_filename.gsub(/.yaml$/, '')
role = settings['role']

# Prepare site.pp symlink depending on role

describe node do
  # Facts
  let :facts do
    {
      :fqdn                 => node,
      :hostname             => node.split(/\./).first,
      :processorcount       => '4',
      :memorysize_mb        => '32138.66',
      :memorysize           => '31.39 GB',
      :kernel               => 'Linux',
      :l3_fqdn_hostname     => node,
      :l3_default_route     => '172.16.1.1',
      :concat_basedir       => '/tmp/',
      :test_yaml            => test_yaml,
      :globas_yaml          => test_yaml + '_globals'
    }
  end

  #######################################
  # Run tests for node
  shared_examples "node (#{astute_filename})" do

    # Test that catalog compiles and there are no dependency cycles in the graph
    it { should compile }
  end # end of shared_examples

  #######################################
  # Testing on different operating systems
  # Ubuntu
  context 'on Ubuntu platforms' do
    before do
      facts.merge!( :osfamily => 'Debian' )
      facts.merge!( :operatingsystem => 'Ubuntu' )
    end
    it_behaves_like "node (#{astute_filename})"
  end

  # CentOS
  context 'on CentOS platforms' do
    before do
      facts.merge!( :osfamily => 'RedHat' )
      facts.merge!( :operatingsystem => 'CentOS' )
    end
    it_behaves_like "node (#{astute_filename})"
  end
end # end of describe node
