# MikroTik CRS309-1G-8S config
# WARNING: for non-production/homelab use only!

# Set hostname:
/system identity set name=sw-prod-a-01

# Set NTP server
/system ntp client set enabled=yes
/system ntp client servers add address=10.101.100.1

# Add bridge:
/interface bridge add name=bridge1

# Ingress behaviour:
/interface bridge port add bridge=bridge1 ingress-filtering=yes frame-types=admit-only-vlan-tagged interface=ether1
/interface bridge port add bridge=bridge1 ingress-filtering=yes frame-types=admit-only-vlan-tagged interface=sfp-sfpplus1
/interface bridge port add bridge=bridge1 ingress-filtering=yes frame-types=admit-only-vlan-tagged interface=sfp-sfpplus2
/interface bridge port add bridge=bridge1 ingress-filtering=yes frame-types=admit-only-vlan-tagged interface=sfp-sfpplus3
/interface bridge port add bridge=bridge1 ingress-filtering=yes frame-types=admit-only-untagged-and-priority-tagged interface=sfp-sfpplus8 pvid=3

# Egress behaviour:
/interface bridge vlan add bridge=bridge1 tagged=bridge1,ether1,sfp-sfpplus1,sfp-sfpplus2,sfp-sfpplus3 untagged=sfp-sfpplus8 vlan-ids=3,100,105,107,109,150,200

# Add VLANs:
/interface vlan add interface=bridge1 name=wan vlan-id=3
/interface vlan add interface=bridge1 name=mgmt vlan-id=100
/interface vlan add interface=bridge1 name=pve-cluster-sync vlan-id=105
/interface vlan add interface=bridge1 name=san-sync vlan-id=107
/interface vlan add interface=bridge1 name=san-repl vlan-id=109
/interface vlan add interface=bridge1 name=vm-public vlan-id=150
/interface vlan add interface=bridge1 name=vm-private vlan-id=200

# Add management IP:
/ip address add address=10.101.100.2/24 interface=mgmt

# Add static route for switch Internet access:
/ip route add dst-address=0.0.0.0/0 gateway=10.101.100.1

# Add switch DNS server:
/ip dns set servers=192.168.2.1

# Add interfaces to lists
/interface list add name=MGMT
/interface list add name=VLAN

/interface list member add list=MGMT interface=mgmt
/interface list member add list=VLAN interface=mgmt
/interface list member add list=VLAN interface=pve-cluster-sync
/interface list member add list=VLAN interface=san-sync
/interface list member add list=VLAN interface=san-repl
/interface list member add list=VLAN interface=vm-public
/interface list member add list=VLAN interface=vm-private

# Firewall
/ip firewall filter
# Input chain
add chain=input action=accept connection-state=established,related
add chain=input action=accept in-interface-list=VLAN
add chain=input action=drop

# Forward chain
add action=fasttrack-connection chain=forward connection-state=established,related hw-offload=yes
add chain=forward action=accept connection-state=established,related
add chain=forward action=drop

# Enable VLAN filtering:
/interface bridge set bridge1 vlan-filtering=yes

# Set MTU and enable flow control:
/interface ethernet set [ find default-name=ether1 ] l2mtu=10218 mtu=10218 rx-flow-control=on tx-flow-control=on
/interface ethernet set [ find default-name=sfp-sfpplus1 ] l2mtu=10218 mtu=10218 rx-flow-control=on tx-flow-control=on
/interface ethernet set [ find default-name=sfp-sfpplus2 ] l2mtu=10218 mtu=10218 rx-flow-control=on tx-flow-control=on
/interface ethernet set [ find default-name=sfp-sfpplus3 ] l2mtu=10218 mtu=10218 rx-flow-control=on tx-flow-control=on
/interface ethernet set [ find default-name=sfp-sfpplus4 ] rx-flow-control=on tx-flow-control=on
/interface ethernet set [ find default-name=sfp-sfpplus5 ] rx-flow-control=on tx-flow-control=on
/interface ethernet set [ find default-name=sfp-sfpplus6 ] rx-flow-control=on tx-flow-control=on
/interface ethernet set [ find default-name=sfp-sfpplus7 ] rx-flow-control=on tx-flow-control=on
/interface ethernet set [ find default-name=sfp-sfpplus8 ] l2mtu=10218 mtu=10218 rx-flow-control=on tx-flow-control=on

# Enable L3 hardware offloading:
/interface/ethernet/switch/port set ether1 l3-hw-offloading=no
/interface/ethernet/switch/port set sfp-sfpplus8 l3-hw-offloading=no
/interface/ethernet/switch set 0 l3-hw-offloading=yes

# Lock down MAC server and Winbox to management interfaces:
/ip neighbor discovery-settings set discover-interface-list=MGMT
/tool mac-server set allowed-interface-list=MGMT
/tool mac-server mac-winbox set allowed-interface-list=MGMT
