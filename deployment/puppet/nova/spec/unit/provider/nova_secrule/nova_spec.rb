require 'pp'
require 'puppet'

provider_class = Puppet::Type.type(:nova_secrule).provider(:nova)

describe provider_class do

  let(:nova_secrule_list) {
<<EOF
+-------------+-----------+---------+--------------+--------------+
| IP Protocol | From Port | To Port | IP Range     | Source Group |
+-------------+-----------+---------+--------------+--------------+
| tcp         | 80        | 80      | 10.0.0.0/8   |              |
| tcp         | 22        | 22      | 10.10.0.0/16 |              |
| udp         | 23        | 23      | 10.0.0.0/8   |              |
+-------------+-----------+---------+--------------+--------------+
EOF
  }

  let(:nova_secrule_source_list) {
<<EOF
+-------------+-----------+---------+------------+--------------+
| IP Protocol | From Port | To Port | IP Range   | Source Group |
+-------------+-----------+---------+------------+--------------+
| udp         | 80        | 80      |            | cluster      |
| udp         | 81        | 81      |            | cluster      |
| udp         | 82        | 82      |            | cluster      |
| tcp         | 80        | 80      | 10.0.0.0/8 |              |
+-------------+-----------+---------+------------+--------------+
EOF
  }

  context 'with ip_range based rules' do

    before :each do
      @resource = Puppet::Type::Nova_secrule.new(
        :name => 'test rule',
        :ip_protocol => 'tcp',
        :from_port => '80',
        :to_port => '80',
        :ip_range => '10.0.0.0/8',
        :security_group => 'test2'
      )
      @provider = provider_class.new(@resource)
    end

    it 'should check existance of the rule' do
      expect(@provider).to receive(:nova).with('secgroup-list-rules', 'test2').and_return(nova_secrule_list)
      expect(@provider.exists?).to be_truthy
      expect(@provider).to receive(:nova).with('secgroup-list-rules', 'test2').and_return('')
      expect(@provider.exists?).to be_falsey
    end

    it 'should be able to create new rule' do
      expect(@provider).to receive(:nova).with('secgroup-add-rule', 'test2', :tcp, '80', '80', '10.0.0.0/8')
      @provider.create
    end

    it 'should be able to destroy rule from group' do
      expect(@provider).to receive(:nova).with('secgroup-delete-rule', 'test2', :tcp, '80', '80', '10.0.0.0/8')
      @provider.destroy
    end

  end

  context 'with source_group based rules' do
    before :each do
      @resource = Puppet::Type::Nova_secrule.new(
        :name => 'test rule',
        :ip_protocol => 'udp',
        :from_port => '80',
        :to_port => '80',
        :source_group => 'cluster',
        :security_group => 'test'
      )
      @provider = provider_class.new(@resource)
    end

    it 'should check existance of the rule' do
      expect(@provider).to receive(:nova).with('secgroup-list-rules', 'test').and_return(nova_secrule_source_list)
      expect(@provider.exists?).to be_truthy
    end

    it 'should be able to create new source rule' do
      expect(@provider).to receive(:nova).with('secgroup-add-group-rule', 'test', 'cluster', :udp, '80', '80')
      @provider.create
    end

    it 'should be able to destroy already existed source rule' do
      expect(@provider).to receive(:nova).with('secgroup-delete-group-rule', 'test', 'cluster', :udp, '80', '80')
      @provider.destroy
    end

  end
end
