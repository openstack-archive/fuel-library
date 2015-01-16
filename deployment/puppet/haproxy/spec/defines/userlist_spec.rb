require 'spec_helper'

describe 'haproxy::userlist' do
  let(:pre_condition) { 'include haproxy' }
  let(:title) { 'admins' }
  let(:facts) do
    {
      :ipaddress      => '1.1.1.1',
      :osfamily       => 'Redhat',
      :concat_basedir => '/dne',
    }
  end

  context "when users and groups are passed" do
    let (:params) do
      {
        :name => "admins",
        :users => [
          'scott insecure-password elgato',
          'kitchen insecure-password foobar' 
        ],
        :groups => [
          'superadmins users kitchen scott',
          'megaadmins users kitchen'
        ]
      }
    end

    it { should contain_concat__fragment('admins_userlist_block').with(
      'order'   => '12-admins-00',
      'target'  => '/etc/haproxy/haproxy.cfg',
      'content' => "\nuserlist admins\n  group superadmins users kitchen scott\n  group megaadmins users kitchen\n  user scott insecure-password elgato\n  user kitchen insecure-password foobar\n"
    ) }

  end
end
