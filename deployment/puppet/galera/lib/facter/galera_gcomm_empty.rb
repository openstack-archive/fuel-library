# galera_gcomm.rb

$result = ""
if gcomm=open("/etc/mysql/conf.d/wsrep.cnf").read.grep(/^\s*wsrep_cluster_address=[\"\']gcomm:\/\/\s*[\"\']\s*/)
    result="true"
else
    result="false"
end

Facter.add("galera_gcomm_empty") do
 setcode do
   $result
   end
end
