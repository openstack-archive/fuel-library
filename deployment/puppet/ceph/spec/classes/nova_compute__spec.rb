require 'spec_helper'

describe 'ceph::nova_compute', :type => :class do

  context 'ceph::nova_compute with defaults' do
    let (:params) do
      {
        :secret_xml      => '/root/.secret_attrs.xml',
        :rbd_secret_uuid => 'a6c179f4-0e40-4d97-8d20-74fad3935e8a',
        :user            => 'compute',
      }
    end

    it { should contain_file(params[:secret_xml]) }
    it { should contain_exec('Set Ceph RBD secret for Nova').that_requires('Service[libvirt]') }

    it { should contain_service('libvirt').with(
      :ensure   => 'running',
    )}

    it { should contain_nova_config('libvirt/rbd_secret_uuid').with(
      :value => params[:rbd_secret_uuid],
    )}

    it { should contain_nova_config('libvirt/rbd_user').with(
      :value => params[:user],
    )}
  end

end
