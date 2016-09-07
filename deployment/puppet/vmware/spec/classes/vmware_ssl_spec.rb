require 'spec_helper'

describe 'vmware::ssl' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts.merge(common_facts) }

      context 'with default parameters' do

        it { is_expected.to compile.with_all_deps }
      end

      context 'with custom parameters' do

        let(:params) do
          {
            :vc_insecure    => false,
            :vc_ca_file     => {
              'content' => 'RSA',
              'name'    => 'vcenter-ca.pem' },
            :vc_ca_filepath => '/etc/nova/vmware-ca.pem',
          }
        end

        it { is_expected.to compile.with_all_deps }

        it { is_expected.to contain_file(params[:vc_ca_filepath]).with(
          :ensure  => 'file',
          :content => 'RSA',
          :mode    => '0644',
          :owner   => 'root',
          :group   => 'root',
        ) }
      end

    end
  end
end
