require 'spec_helper'

describe 'cgroups', :type => :class do
  context "on a Debian OS" do
    let :facts do
      {
        :osfamily               => 'Debian',
        :operatingsystem        => 'Ubuntu',
      }
    end

    let :file_defaults do
      {
        :ensure  => :file,
        :owner   => 'root',
        :group   => 'root',
        :mode    => '0644',
        :tag     => 'cgroups',
      }
    end

    let (:params) {{ :cgroups_set => {} }}

    it { is_expected.to compile }
    it {
      should contain_class('cgroups::service').with(
        :cgroups_settings => params[:cgroups_set])
    }

    %w(libcgroup1 cgroup-bin cgroup-upstart).each do |cg_pkg|
      it { is_expected.to contain_package(cg_pkg) }
    end

    %w(/etc/cgconfig.conf /etc/cgrules.conf).each do |cg_file|
      it { is_expected.to contain_file(cg_file).that_notifies('[Service[cgrulesengd], Service[cgconfigparser]]').with(file_defaults) }
      it { p catalogue.resource 'file', cg_file }
    end
  end
end
