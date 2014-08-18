module NeutronDBMigration
    def self.exec(cmd)
        result = Facter::Util::Resolution.exec("#{cmd}", '/bin/bash')
        result.split("\n")
    end

    def self.current_stamp
        rv = exec('/usr/bin/neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugin.ini current')
        if rv && rv.is_a?(Array) && rv.length > 0
            return rv[0].split(',')[-1].strip
        else
            return 'nil'
        end
    end
end

Facter.add('neutron_db_migration_stamp') do
  setcode do
    NeutronDBMigration.current_stamp
  end
end