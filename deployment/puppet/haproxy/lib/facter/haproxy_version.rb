# Fact: haproxy_version
#
# Purpose: get haproxy's current version
#
# Resolution:
#   Uses haproxy's -v flag and parses the result from 'version'
#
# Caveats:
#   none
#
# Notes:
#   None
if Facter::Util::Resolution.which('haproxy')
  Facter.add('haproxy_version') do
    haproxy_version_cmd = 'haproxy -v 2>&1'
    haproxy_version_result = Facter::Util::Resolution.exec(haproxy_version_cmd)
    setcode do
      haproxy_version_result.to_s.lines.first.strip.split(/HA-Proxy/)[1].strip.split(/version/)[1].strip.split(/((\d+\.){2,}\d+).*/)[1]
    end
  end
end

