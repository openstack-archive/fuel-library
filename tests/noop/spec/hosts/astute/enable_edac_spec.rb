require 'spec_helper'
require 'shared-examples'
manifest = 'astute/enable_edac.pp'



$insert_module_cmd = $::osfamily ? {
  'Debian' => "echo '${modulename}' >> '${modulesfile}'",
  'RedHat' => "echo 'modprobe ${modulename}' >> '${modulesfile}'"
}

$insert_unless_cmd = $::osfamily ? {
  'Debian' => "grep -qFx '${modulename}' '${modulesfile}'",
  'RedHat' => "grep -q '^modprobe ${modulename}\$' '${modulesfile}'"
}

exec { "insert_module_${modulename}":
  path    => '/sbin:/usr/bin:/usr/sbin:/bin',
  command => $insert_module_cmd,
  unless  => $insert_unless_cmd,
}

exec { "modprobe ${modulename}":
  path    => '/sbin:/usr/bin:/usr/sbin:/bin',
  command => "modprobe ${modulename}",
  unless  => "grep -q '^${modulename} ' '/proc/modules'"
}



describe manifest do
  shared_examples 'catalog' do

    it "should enable edac module" do
      modulename = 'edac_core'

      case facts[:operatingsystem]
      when 'Ubuntu'
        insert_module_cmd = "echo ${modulename}' >> '${modulesfile}'"
        insert_unless_cmd = "grep -qFx '${modulename'} '/etc/modules'"
      when 'CentOS'
        insert_module_cmd = "echo ${modulename}' >> '/etc/rc.modules'"
        insert_unless_cmd = "grep -qFx '${modulename'} '/etc/rc.modules'"
      end

      is_expected.to contain_exec('insert_module_${modulename}').with(
          :path    => ['/sbin', '/usr/bin', '/usr/sbin:/bin'],
          :command => insert_module_cmd,
          :unless  => insert_unless_cmd,
        )

      is_expected.to contain_exec('insert_module_${modulename}').with(
          :path    => ['/sbin', '/usr/bin', '/usr/sbin:/bin'],
          :command => "modprobe ${modulename}",
          :unless  => "grep -q '^${modulename} ' '/proc/modules'"
        )
    end
  end
  test_ubuntu_and_centos manifest
end
