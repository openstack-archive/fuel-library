require 'spec_helper_system'

describe 'mongodb::install' do
  case node.facts['osfamily']
  when 'RedHat'
    package_name = 'mongodb-server'
  when 'Debian'
    package_name = 'mongodb'
  end

  it 'runs setup' do
    pp = <<-EOS
    class { 'mongodb': }
    EOS
    puppet_apply(pp)
  end

  describe package(package_name) do
    it { should be_installed }
  end

end
