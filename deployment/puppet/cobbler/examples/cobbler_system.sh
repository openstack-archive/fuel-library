cobbler system add --name="fuel-01" \
	--profile="centos63-x86_64" \
	--netboot-enabled=True  \
	--ksmeta="puppet_auto_setup=1 puppet_master=lenin.msk.mirantis.net" \
	--hostname="fuel-01" \
	--name-servers=10.0.0.100 \
	--name-servers-search="mirantis.com" \
	--gateway=10.0.0.100

cobbler system edit --name="fuel-01" \
	--interface=eth0 \
	--mac=52:54:00:87:41:04 \
	--static=False

cobbler system edit --name="fuel-01" \
	--interface=eth1 \
	--mac=52:54:00:29:83:e7 \
	--static=True \
	--dns-name="fuel-01.mirantis.com" \
	--ip-address=10.0.0.101 \
	--netmask=255.255.255.0 \
	--management=True

cobbler system edit --name="fuel-01" \
	--interface=eth2 \
	--mac=52:54:00:9a:92:45

