case Facter.value(:osfamily)
  when 'Debian'
    Facter.add('pkglist') do
      setcode "dpkg-query -W -f='${binary:Package}\n'"
    end
  when 'Redhat'
    Facter.add('pkglist') do
      setcode "rpm -qa"
    end
end
