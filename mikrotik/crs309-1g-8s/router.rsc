# MikroTik CRS309-1G-8S config
# WARNING: for non-production/homelab use only!

# Set hostname:
/system identity set name=sw-prod-a-01

# Add bridge:
/interface bridge add name=bridge1

# Add ports:
/interface bridge port add bridge=bridge1 interface=ether1 pvid=100
/interface bridge port add bridge=bridge1 interface=sfp-sfpplus8 pvid=3
/interface bridge port add bridge=bridge1 frame-types=admit-only-vlan-tagged interface=sfp-sfpplus1
/interface bridge port add bridge=bridge1 frame-types=admit-only-vlan-tagged interface=sfp-sfpplus2

# Add VLANs:
/interface vlan add interface=bridge1 name=wan vlan-id=3
/interface vlan add interface=bridge1 name=mgmt vlan-id=100
/interface vlan add interface=bridge1 name=pve-cluster-sync vlan-id=105
/interface vlan add interface=bridge1 name=san-sync vlan-id=107
/interface vlan add interface=bridge1 name=san-repl vlan-id=109
/interface vlan add interface=bridge1 name=vm-public vlan-id=150
/interface vlan add interface=bridge1 name=vm-private vlan-id=200

# Add VLANs to ports:
/interface bridge vlan add bridge=bridge1 tagged=bridge1,sfp-sfpplus1,sfp-sfpplus2 untagged=ether1,sfp-sfpplus8 vlan-ids=3,100,105,107,109,150,200

# Add management IP:
/ip address add address=10.101.100.2/24 interface=mgmt

# Add static route for switch Internet access:
/ip route add dst-address=0.0.0.0/0 gateway=10.101.100.1

# Add switch DNS server:
/ip dns set servers=192.168.2.1

# Lock down MAC server and Winbox to management interfaces:
/interface list add name=mgmt-list
/interface list member add list=mgmt-list interface=mgmt
/ip neighbor discovery-settings set discover-interface-list=mgmt-list
/tool mac-server set allowed-interface-list=mgmt-list
/tool mac-server mac-winbox set allowed-interface-list=mgmt-list

# VLAN security:
/interface bridge set bridge1 vlan-filtering=yes

# Enable flow control:
/interface ethernet set [ find default-name=ether1 ] l2mtu=10218 mtu=10218 rx-flow-control=on tx-flow-control=on
/interface ethernet set [ find default-name=sfp-sfpplus1 ] l2mtu=10218 mtu=10218 rx-flow-control=on tx-flow-control=on
/interface ethernet set [ find default-name=sfp-sfpplus2 ] l2mtu=10218 mtu=10218 rx-flow-control=on tx-flow-control=on
/interface ethernet set [ find default-name=sfp-sfpplus3 ] rx-flow-control=on tx-flow-control=on
/interface ethernet set [ find default-name=sfp-sfpplus4 ] rx-flow-control=on tx-flow-control=on
/interface ethernet set [ find default-name=sfp-sfpplus5 ] rx-flow-control=on tx-flow-control=on
/interface ethernet set [ find default-name=sfp-sfpplus6 ] rx-flow-control=on tx-flow-control=on
/interface ethernet set [ find default-name=sfp-sfpplus7 ] rx-flow-control=on tx-flow-control=on
/interface ethernet set [ find default-name=sfp-sfpplus8 ] l2mtu=10218 mtu=10218 rx-flow-control=on tx-flow-control=on

# Enable L3 hardware offloading:
/ip firewall filter add action=fasttrack-connection chain=forward connection-state=established,related hw-offload=yes
/ip firewall filter add action=accept chain=forward connection-state=established,related
/interface/ethernet/switch/port set ether1 l3-hw-offloading=no
/interface/ethernet/switch/port set sfp-sfpplus8 l3-hw-offloading=no
/interface/ethernet/switch set 0 l3-hw-offloading=yes
