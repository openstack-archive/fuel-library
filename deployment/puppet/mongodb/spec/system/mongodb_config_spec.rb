require 'spec_helper_system'

describe 'mongodb::config' do
  config_file = '/etc/mongodb.conf'

  it 'runs setup' do
    pp = <<-EOS
    class { 'mongodb': }
    EOS
    puppet_apply(pp)
  end

  describe file(config_file) do
    it { should be_file }
  end

end
