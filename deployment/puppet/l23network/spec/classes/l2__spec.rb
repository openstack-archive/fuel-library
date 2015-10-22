require 'spec_helper'

describe 'l23network::l2' do

  context 'CentOS 7' do
    let (:facts) do
      { :l23_os           => 'centos7',
        :l3_fqdn_hostname => 'my_name',
      }
    end

    let :pre_condition do
       'K_mod <| |>'
    end

    puppet_debug_override

    context 'with a default params' do
       let :params do
        { }
      end

      it { should compile.with_all_deps }

      it { should_not contain_package('openvswitch-datapath') }

      it { should_not contain_package('openvswitch-common').with_name('openvswitch') }

      it { should_not contain_service('openvswitch-service') }

      it { should_not contain_k_mod('openvswitch').with_ensure('present') }

      it { should contain_k_mod('bonding') }
      it { should contain_k_mod('8021q') }
      it { should contain_k_mod('bridge') }

    end

    context 'use_ovs with default parameters' do

      let :params do
      { :ensure_package               => 'present',
        :use_lnx                      => true,
        :use_ovs                      => true,
      }
      end

      it { should compile.with_all_deps }

      it { should contain_package('openvswitch-datapath').with_name('kmod-openvswitch') }
      it { should contain_package('openvswitch-datapath').that_comes_before('Service[openvswitch-service]') }

      it { should contain_package('openvswitch-common').with_name('openvswitch') }
      it { should contain_package('openvswitch-common').that_notifies('Service[openvswitch-service]') }

      it { should contain_service('openvswitch-service') }

      it { should contain_k_mod('openvswitch').with_ensure('present') }

    end

    context 'use_ovs and custom ovs_datapath_package_name and custom ovs_module_name and ovs_common_package_name' do

      let :params do
      { :ensure_package               => 'present',
        :use_lnx                      => true,
        :use_ovs                      => true,
        :ovs_module_name              => 'custom_ovs_module_name',
        :ovs_datapath_package_name    => 'custom_ovs_datapath_package_name',
        :ovs_common_package_name      => 'test_ovs_common_package_name',
      }
      end

      it { should compile.with_all_deps }

      it { should contain_package('openvswitch-datapath').with_name('custom_ovs_datapath_package_name') }
      it { should contain_package('openvswitch-datapath').that_comes_before('Service[openvswitch-service]') }

      it { should contain_package('openvswitch-common').with_name('test_ovs_common_package_name') }
      it { should contain_package('openvswitch-common').that_notifies('Service[openvswitch-service]') }

      it { should contain_service('openvswitch-service') }

      it { should contain_k_mod('custom_ovs_module_name').with_ensure('present') }

    end

    context 'use_ovs with disabled dkms ovs module' do

      let :params do
      { :ensure_package               => 'present',
        :use_lnx                      => true,
        :use_ovs                      => true,
        :use_ovs_dkms_datapath_module => false,
      }
      end

      it { should compile.with_all_deps }

      it { should_not contain_package('openvswitch-datapath').with_name('kmod-openvswitch') }

      it { should contain_package('openvswitch-common').with_name('openvswitch') }
      it { should contain_package('openvswitch-common').that_notifies('Service[openvswitch-service]') }

      it { should contain_service('openvswitch-service') }

      it { should contain_k_mod('openvswitch').with_ensure('present') }

    end

  end


  context 'Ubuntu' do
    let (:facts) do
      { :l23_os           => 'ubuntu',
        :l3_fqdn_hostname => 'my_name',
      }
    end

    let :pre_condition do
       'K_mod <| |>'
    end

    puppet_debug_override

    context 'with a default params' do
       let :params do
        { }
      end

      it { should compile.with_all_deps }

      it { should_not contain_package('openvswitch-datapath') }

      it { should_not contain_package('openvswitch-common') }

      it { should_not contain_service('openvswitch-service') }

      it { should_not contain_k_mod('openvswitch').with_ensure('present') }

      it { should contain_k_mod('bonding') }
      it { should contain_k_mod('8021q') }
      it { should contain_k_mod('bridge') }

    end

    context 'use_ovs with default parameters' do

      let :params do
      { :ensure_package               => 'present',
        :use_lnx                      => true,
        :use_ovs                      => true,
      }
      end

      it { should compile.with_all_deps }

      it { should contain_package('openvswitch-datapath').with_name('openvswitch-datapath-dkms') }
      it { should contain_package('openvswitch-datapath').that_comes_before('Service[openvswitch-service]') }

      it { should contain_package('openvswitch-common').with_name('openvswitch-switch') }
      it { should contain_package('openvswitch-common').that_notifies('Service[openvswitch-service]') }

      it { should contain_service('openvswitch-service') }

      it { should contain_k_mod('openvswitch').with_ensure('present') }

    end

    context 'use_ovs and custom ovs_datapath_package_name and custom ovs_module_name and ovs_common_package_name' do

      let :params do
      { :ensure_package               => 'present',
        :use_lnx                      => true,
        :use_ovs                      => true,
        :ovs_module_name              => 'custom_ovs_module_name',
        :ovs_datapath_package_name    => 'custom_ovs_datapath_package_name',
        :ovs_common_package_name      => 'test_ovs_common_package_name',
      }
      end

      it { should compile.with_all_deps }

      it { should contain_package('openvswitch-datapath').with_name('custom_ovs_datapath_package_name') }
      it { should contain_package('openvswitch-datapath').that_comes_before('Service[openvswitch-service]') }

      it { should contain_package('openvswitch-common').with_name('test_ovs_common_package_name') }
      it { should contain_package('openvswitch-common').that_notifies('Service[openvswitch-service]') }

      it { should contain_service('openvswitch-service') }

      it { should contain_k_mod('custom_ovs_module_name').with_ensure('present') }

    end

    context 'use_ovs with disabled dkms ovs module' do

      let :params do
      { :ensure_package               => 'present',
        :use_lnx                      => true,
        :use_ovs                      => true,
        :use_ovs_dkms_datapath_module => false,
      }
      end

      it { should compile.with_all_deps }

      it { should_not contain_package('openvswitch-datapath').with_name('openvswitch-datapath-dkms') }

      it { should contain_package('openvswitch-common').with_name('openvswitch-switch') }
      it { should contain_package('openvswitch-common').that_notifies('Service[openvswitch-service]') }

      it { should contain_service('openvswitch-service') }

      it { should contain_k_mod('openvswitch').with_ensure('present') }

    end

  end


end
