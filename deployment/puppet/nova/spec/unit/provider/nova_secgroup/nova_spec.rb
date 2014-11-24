require 'pp'
require 'puppet'

provider_class = Puppet::Type.type(:nova_secgroup).provider(:nova)

describe provider_class do

  let(:nova_secgroup_list) {
<<EOF
+--------------------------------------+---------+--------------+
| Id                                   | Name    | Description  |
+--------------------------------------+---------+--------------+
| 07036a72-9951-419c-b413-bd256012d0a6 | cluster | cluster      |
| 0613cad1-f4ea-4678-a20b-bf57bf1af33d | default | default      |
| 38c042f7-4888-46d9-81ff-99d5b3a2c68f | test    | my secgroup  |
| 1e7f3448-2eb3-4b80-a531-b44a01bd34aa | test2   | 123          |
+--------------------------------------+---------+--------------+
EOF
  }

  let(:secgroup_hash) {
    {"cluster"=>"cluster", "default"=>"default", "test"=>"my secgroup", "test2"=>"123"}
  }

  before :each do
    @resource = Puppet::Type::Nova_secgroup.new(
      {
        :name => 'test',
        :description => 'my secgroup',
      }
    )
    @provider = provider_class.new(@resource)
  end

  it 'should list existing nova secgroups' do
    expect(@provider).to receive(:nova).with('secgroup-list').and_return(nova_secgroup_list)
    expect(@provider.list).to eq(secgroup_hash)
    expect(@provider).to receive(:nova).with('secgroup-list').and_return('')
    expect(@provider.list).to eq({})
  end 

  it 'should check existance of a secgroup' do
    expect(@provider).to receive(:list).and_return(secgroup_hash)
    expect(@provider.exists?).to be_truthy
    expect(@provider).to receive(:list).and_return({})
    expect(@provider.exists?).to be_falsey
  end

  it 'should be able to get the desctiption of a group' do
    expect(@provider).to receive(:list).and_return(secgroup_hash)
    expect(@provider.description).to eq('my secgroup')
    expect(@provider).to receive(:list).and_return({})
    expect(@provider.description).to be_nil
  end

  it 'should be able to update the description of a group' do
    expect(@provider).to receive(:nova).with('secgroup-update', 'test', 'test', 'new description')
    @provider.description = 'new description'
  end

  it 'should be able to create a new secgroup' do
    expect(@provider).to receive(:nova).with('secgroup-create', 'test', 'my secgroup')
    @provider.create
  end

  it 'should be able to delete a secgroup' do
    expect(@provider).to receive(:nova).with('secgroup-delete', 'test')
    @provider.destroy
  end


end
