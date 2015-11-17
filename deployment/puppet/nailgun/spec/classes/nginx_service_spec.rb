require 'spec_helper'

describe 'nailgun::nginx-service' do
  it 'should contain X-Frame-Options SAMEORIGIN header' do
    should contain_file('/etc/nginx/nginx.conf').with_content(/^\s*add_header X-Frame-Options SAMEORIGIN;$/)
  end
end
