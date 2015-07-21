require 'puppet'
require 'spec_helper'
require 'puppet/provider/keystone_user_role/openstack'

provider_class = Puppet::Type.type(:keystone_user_role).provider(:openstack)
def user_class
  Puppet::Type.type(:keystone_user).provider(:openstack)
end
def project_class
  Puppet::Type.type(:keystone_tenant).provider(:openstack)
end

describe provider_class do

  # assumes Enabled is the last column - no quotes
  def list_to_csv(thelist)
    if thelist.is_a?(String)
      return ''
    end
    str=""
    thelist.each do |rec|
      if rec.is_a?(String)
        return ''
      end
      rec.each do |xx|
        if xx.equal?(rec.last)
          # True/False have no quotes
          if xx == 'True' or xx == 'False'
            str = str + xx + "\n"
          else
            str = str + '"' + xx + '"' + "\n"
          end
        else
          str = str + '"' + xx + '",'
        end
      end
    end
    str
  end

  def before_need_instances
    provider.class.expects(:openstack).once
      .with('domain', 'list', '--quiet', '--format', 'csv')
      .returns('"ID","Name","Enabled","Description"
"foo_domain_id","foo_domain",True,"foo domain"
"bar_domain_id","bar_domain",True,"bar domain"
"another_domain_id","another_domain",True,"another domain"
"disabled_domain_id","disabled_domain",False,"disabled domain"
')
    project_list = [['project-id-1','foo','foo_domain_id','foo project in foo domain','True'],
                    ['project-id-2','foo','bar_domain_id','foo project in bar domain','True'],
                    ['project-id-3','bar','foo_domain_id','bar project in foo domain','True'],
                    ['project-id-4','etc','another_domain_id','another project','True']]

    user_list_for_project = {
      'project-id-1' => [['user-id-1','foo@example.com','foo','foo_domain','foo user','foo@foo_domain','True'],
                         ['user-id-2','bar@example.com','foo','foo_domain','bar user','bar@foo_domain','True']],
      'project-id-2' => [['user-id-3','foo@bar.com','foo','bar_domain','foo user','foo@bar_domain','True'],
                         ['user-id-4','bar@bar.com','foo','bar_domain','bar user','bar@bar_domain','True']]
    }
    user_list_for_project.default = ''

    user_list_for_domain = {
      'foo_domain_id' => [['user-id-1','foo@example.com','foo','foo_domain','foo user','foo@foo_domain','True'],
                          ['user-id-2','bar@example.com','foo','foo_domain','bar user','bar@foo_domain','True']],
      'bar_domain_id' => [['user-id-3','foo@bar.com','foo','bar_domain','foo user','foo@bar_domain','True'],
                          ['user-id-4','bar@bar.com','foo','bar_domain','bar user','bar@bar_domain','True']]
    }
    user_list_for_domain.default = ''

    role_list_for_project_user = {
      'project-id-1' => {
        'user-id-1' => [['role-id-1','foo','foo','foo'],
                        ['role-id-2','bar','foo','foo']]
      },
      'project-id-2' => {
        'user-id-3' => [['role-id-1','foo','foo','foo'],
                        ['role-id-2','bar','foo','foo']]
      }
    }
    role_list_for_project_user.default = ''

    role_list_for_domain_user = {
      'foo_domain_id' => {
        'user-id-2' => [['role-id-1','foo','foo_domain','foo'],
                        ['role-id-2','bar','foo_domain','foo']]
      },
      'bar_domain_id' => {
        'user-id-4' => [['role-id-1','foo','bar_domain','foo'],
                        ['role-id-2','bar','bar_domain','foo']]
      }
    }
    role_list_for_project_user.default = ''

    provider.class.expects(:openstack).once
                  .with('project', 'list', '--quiet', '--format', 'csv', ['--long'])
                  .returns('"ID","Name","Domain ID","Description","Enabled"' + "\n" + list_to_csv(project_list))
    project_list.each do |rec|
      csvlist = list_to_csv(user_list_for_project[rec[0]])
      provider.class.expects(:openstack)
                    .with('user', 'list', '--quiet', '--format', 'csv', ['--long', '--project', rec[0]])
                    .returns('"ID","Name","Project","Domain","Description","Email","Enabled"' + "\n" + csvlist)
      next if csvlist == ''
      user_list_for_project[rec[0]].each do |urec|
        csvlist = ''
        if role_list_for_project_user.has_key?(rec[0]) and
            role_list_for_project_user[rec[0]].has_key?(urec[0])
          csvlist = list_to_csv(role_list_for_project_user[rec[0]][urec[0]])
        end
        provider.class.expects(:openstack)
                      .with('role', 'list', '--quiet', '--format', 'csv', ['--project', rec[0], '--user', urec[0]])
                      .returns('"ID","Name","Project","User"' + "\n" + csvlist)
      end
    end
    ['foo_domain_id', 'bar_domain_id'].each do |domid|
      csvlist = list_to_csv(user_list_for_domain[domid])
      provider.class.expects(:openstack)
                    .with('user', 'list', '--quiet', '--format', 'csv', ['--long', '--domain', domid])
                    .returns('"ID","Name","Project","Domain","Description","Email","Enabled"' + "\n" + csvlist)
      next if csvlist == ''
      user_list_for_domain[domid].each do |urec|
        csvlist = ''
        if role_list_for_domain_user.has_key?(domid) and
            role_list_for_domain_user[domid].has_key?(urec[0])
          csvlist = list_to_csv(role_list_for_domain_user[domid][urec[0]])
        end
        provider.class.expects(:openstack)
                      .with('role', 'list', '--quiet', '--format', 'csv', ['--domain', domid, '--user', urec[0]])
                      .returns('"ID","Name","Domain","User"' + "\n" + csvlist)
      end
    end
  end

  def before_common(destroy, nolist=false, instances=false)
    rolelistprojectuser = [['role-id-1','foo','foo','foo'],
                           ['role-id-2','bar','foo','foo']]
    csvlist = list_to_csv(rolelistprojectuser)
    rolelistreturns = ['"ID","Name","Project","User"' + "\n" + csvlist]
    nn = 1
    if destroy
      rolelistreturns = ['']
      nn = 1
    end
    unless nolist
      provider.class.expects(:openstack).times(nn)
                    .with('role', 'list', '--quiet', '--format', 'csv', ['--project', 'project-id-1', '--user', 'user-id-1'])
                    .returns(*rolelistreturns)
    end

    userhash = {:id => 'user-id-1', :name => 'foo@example.com'}
    usermock = user_class.new(userhash)
    unless instances
      usermock.expects(:exists?).with(any_parameters).returns(true)
      user_class.expects(:new).twice.with(any_parameters).returns(usermock)
    end
    user_class.expects(:instances).with(any_parameters).returns([usermock])

    projecthash = {:id => 'project-id-1', :name => 'foo'}
    projectmock = project_class.new(projecthash)
    unless instances
      projectmock.expects(:exists?).with(any_parameters).returns(true)
      project_class.expects(:new).with(any_parameters).returns(projectmock)
    end
    project_class.expects(:instances).with(any_parameters).returns([projectmock])
  end

  before :each, :default => true do
    before_common(false)
  end

  before :each, :destroy => true do
    before_common(true)
  end

  before :each, :nolist => true do
    before_common(true, true)
  end

  before :each, :instances => true do
    before_common(true, true, true)
  end

  shared_examples 'authenticated with environment variables' do
    ENV['OS_USERNAME']     = 'test'
    ENV['OS_PASSWORD']     = 'abc123'
    ENV['OS_PROJECT_NAME'] = 'test'
    ENV['OS_AUTH_URL']     = 'http://127.0.0.1:5000'
  end

  describe 'when updating a user\'s role' do
    it_behaves_like 'authenticated with environment variables' do
      let(:user_role_attrs) do
        {
          :name         => 'foo@foo',
          :ensure       => 'present',
          :roles        => ['foo', 'bar'],
        }
      end

      let(:resource) do
        Puppet::Type::Keystone_user_role.new(user_role_attrs)
      end

      let(:provider) do
        provider_class.new(resource)
      end

      describe '#create', :default => true do
        it 'adds all the roles to the user' do
          provider.class.expects(:openstack)
                        .with('role', 'add', ['foo', '--project', 'project-id-1', '--user', 'user-id-1'])
          provider.class.expects(:openstack)
                        .with('role', 'add', ['bar', '--project', 'project-id-1', '--user', 'user-id-1'])
          provider.create
          expect(provider.exists?).to be_truthy
        end
      end

      describe '#destroy', :destroy => true do
        it 'removes all the roles from a user' do
          provider.instance_variable_get('@property_hash')[:roles] = ['foo', 'bar']
          provider.class.expects(:openstack)
                        .with('role', 'remove', ['foo', '--project', 'project-id-1', '--user', 'user-id-1'])
          provider.class.expects(:openstack)
                        .with('role', 'remove', ['bar', '--project', 'project-id-1', '--user', 'user-id-1'])
          provider.destroy
          expect(provider.exists?).to be_falsey
        end

      end

      describe '#exists', :default => true do
        subject(:response) do
          response = provider.exists?
        end

        it { is_expected.to be_truthy }

      end

      describe '#instances', :instances => true do
        it 'finds every user role' do
          provider.class.expects(:openstack)
                        .with('role', 'list', '--quiet', '--format', 'csv', [])
                        .returns('"ID","Name"
"foo-role-id","foo"
"bar-role-id","bar"
')
          provider.class.expects(:openstack)
                        .with('role assignment', 'list', '--quiet', '--format', 'csv', [])
                        .returns('
"Role","User","Group","Project","Domain"
"foo-role-id","user-id-1","","project-id-1",""
"bar-role-id","user-id-1","","project-id-1",""
')
          instances = provider.class.instances
          expect(instances.count).to eq(1)
          expect(instances[0].name).to eq('foo@example.com@foo')
          expect(instances[0].roles).to eq(['foo', 'bar'])
        end
      end

      describe '#roles=', :nolist => true do
        let(:user_role_attrs) do
          {
            :name         => 'foo@foo',
            :ensure       => 'present',
            :roles        => ['one', 'two'],
          }
        end

        it 'applies the new roles' do
          provider.instance_variable_get('@property_hash')[:roles] = ['foo', 'bar']
          provider.class.expects(:openstack)
                        .with('role', 'remove', ['foo', '--project', 'project-id-1', '--user', 'user-id-1'])
          provider.class.expects(:openstack)
                        .with('role', 'remove', ['bar', '--project', 'project-id-1', '--user', 'user-id-1'])
          provider.class.expects(:openstack)
                        .with('role', 'add', ['one', '--project', 'project-id-1', '--user', 'user-id-1'])
          provider.class.expects(:openstack)
                        .with('role', 'add', ['two', '--project', 'project-id-1', '--user', 'user-id-1'])
          provider.roles=(['one', 'two'])
        end
      end
    end
  end
end
