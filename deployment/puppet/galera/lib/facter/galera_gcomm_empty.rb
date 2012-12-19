# galera_gcomm.rb

result = "true"
if File.exists?("/etc/mysql/conf.d/wsrep.cnf")
    if open("/etc/mysql/conf.d/wsrep.cnf").read.grep(/^\s*wsrep_cluster_address=[\"\']gcomm:\/\/\s*[\"\']\s*/).any?
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
