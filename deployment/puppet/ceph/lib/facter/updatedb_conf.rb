# Fact: updatedb_prunepaths
#
# Purpose: Return PRUNEPATHS value from /etc/updatedb.conf
#
require 'augeas'
Facter.add(:updatedb_prunepaths) do
  setcode do
    Augeas.open(nil, '/', Augeas::NO_MODL_AUTOLOAD) do |aug|
      aug.transform(
        :lens => 'Simplevars.lns',
        :incl => '/etc/updatedb.conf',
      )
      aug.load!
      aug.get('/files/etc/updatedb.conf/PRUNEPATHS').gsub(/['"]/, '')
    end
  end
end
