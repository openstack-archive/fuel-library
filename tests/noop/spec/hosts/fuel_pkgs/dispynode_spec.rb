# ROLE: *
require 'spec_helper'
require 'shared-examples'
manifest = 'fuel_pkgs/dispynode.pp'

describe manifest do
  shared_examples 'catalog' do
    # group
    # user
    # file
    # package
    # init
    it {should create_class('osnailyfacter::fuel_pkgs::dispynode')}
    let(:node) {'node-1.test.domain.local'}
    it 'should create user and group with name dispy' do
      should contain_group('dispy')
      should contain_user('dispy')
    end
    it 'dispynode should contain /var/lib/dispy' do
      should contain_file('/var/lib/dispy').with(
                                                'ensure' => 'directory',
                                                'owner'  => 'dispy',
                                                'group'  => 'dispy',
                                                'mode'   => '0750'
                                                )
    end
    context 'install python-dispy' do
      it {should contain_package('python-dispy')}
    end
    it 'should run dispynode' do
      should contain_service('dispynode.py').with(
                                               'ensure' => 'running'
                                              )
    end
  end

 test_ubuntu_and_centos manifest
end
