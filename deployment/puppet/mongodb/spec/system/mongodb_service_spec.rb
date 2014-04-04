require 'spec_helper_system'

describe 'mongodb::service' do

  case node.facts['osfamily']
  when 'RedHat'
    service_name = 'mongod'
  else
    service_name = 'mongodb'
  end

  it 'runs setup' do
    pp = <<-EOS
    class { 'mongodb': }
    EOS
    puppet_apply(pp)
  end

  describe service(service_name) do
    it { should be_enabled }
    it { should be_running }
  end

end
