require 'spec_helper'
describe 'swift::storage::xfs' do
  let :title do
    'foo'
  end
  describe 'when a device is not specified' do
    it 'should raise an error' do
      expect { subject }.to raise_error(Puppet::Error)
    end
  end

  describe 'when a device is specified' do
    let :default_params do
      {
       :device       => 'some_device',
       :byte_size    => '1024',
       :mnt_base_dir => '/srv/node',
       :loopback     => false
      }
    end

    [{:device       => 'some_device'},
     {
       :device       => 'some_device',
       :byte_size    => 1,
       :mnt_base_dir => '/mnt/foo',
       :loopback     => true
     }
    ].each do |param_set|

      describe "#{param_set == {} ? "using default" : "specifying"} class parameters" do
        let :param_hash do
          default_params.merge(param_set)
        end

        let :params do
          param_set
        end

        it { should contain_exec("mkfs-foo").with(
          :command     => "mkfs.xfs -i size=#{param_hash[:byte_size]} #{param_hash[:device]}",
          :path        => '/sbin/',
          :refreshonly => true,
          :require     => 'Package[xfsprogs]'
        )}

        it { should contain_swift__storage__mount('foo').with(
           :device       => param_hash[:device],
           :mnt_base_dir => param_hash[:mnt_base_dir],
           :loopback     => param_hash[:loopback],
           :subscribe    => 'Exec[mkfs-foo]'
        )}

      end
    end
  end
end
