require 'spec_helper'

describe 'fuel::nginx' do
  shared_examples_for "fuel nginx" do
    it 'should contain X-Frame-Options SAMEORIGIN header' do
      should contain_file('/etc/nginx/nginx.conf').with_content(/^\s*add_header X-Frame-Options SAMEORIGIN;$/)
    end
  end

  on_supported_os(supported_os: supported_os).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      it_configures "fuel nginx"
    end
  end
end
