# Fact: galera_gcomm_empty
#
# Purpose: Return 'true' if gcomm:// cluster address is empty for Galera MySQL master-master replication engine 
#
# Resolution:
#   Greps mysql config files for wsrep_cluster_address option 
#
# Caveats:
#

## Cfkey.rb
## Facts related to cfengine
##

result = "true"
#FIXME: do not hardcode wsrep config file location. We need to start from 
#FIXME:  mysql config file and go through all the include directives

if File.exists?("/etc/mysql/conf.d/wsrep.cnf")   
    if open("/etc/mysql/conf.d/wsrep.cnf").read.split("\n").grep(/^\s*wsrep_cluster_address=[\"\']gcomm:\/\/\s*[\"\']\s*/).any?
        result="true"
    else
        result="false"
    end
end

Facter.add("galera_gcomm_empty") do
 setcode do
   result
   end
end
