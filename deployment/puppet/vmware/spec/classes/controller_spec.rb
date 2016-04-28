require 'spec_helper'

describe 'vmware::controller' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }

      xit { is_expected.to compile.with_all_deps }

      xit 'must disable nova-compute' do
        should contain_nova__generic_service('compute').with({
                                                                 'enabled' => 'false'
                                                             })
      end

      xit 'must properly configure novncproxy_base_url' do
        should contain_nova_config('DEFAULT/novncproxy_base_url').with({
                                                                           'value' => "http://0.0.0.0:6080/vnc_auto.html",
                                                                       })
      end

      xit 'must install cirros-testvmware package' do
        should contain_package('cirros-testvmware')
      end

      xit 'must install python-suds package' do
        should contain_package('python-suds')
      end

    end
  end
end