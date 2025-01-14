# MikroTik CRS309-1G-8S config
# WARNING: for non-production/homelab use only!

# Set hostname:
/system identity set name=sw-prod-a-01

# Add bridge:
/interface bridge add name=bridge1

# Ingress behaviour:
/interface bridge port add bridge=bridge1 ingress-filtering=yes frame-types=admit-only-vlan-tagged interface=ether1
/interface bridge port add bridge=bridge1 ingress-filtering=yes frame-types=admit-only-vlan-tagged interface=sfp-sfpplus1
/interface bridge port add bridge=bridge1 ingress-filtering=yes frame-types=admit-only-vlan-tagged interface=sfp-sfpplus2

# Egress behaviour:
/interface bridge vlan add bridge=bridge1 tagged=bridge1,ether1,sfp-sfpplus1,sfp-sfpplus2 vlan-ids=100,105,107,109,150,200

# Add VLANs:
/interface vlan add interface=bridge1 name=mgmt vlan-id=100
/interface vlan add interface=bridge1 name=pve-cluster-sync vlan-id=105
/interface vlan add interface=bridge1 name=san-sync vlan-id=107
/interface vlan add interface=bridge1 name=san-repl vlan-id=109
/interface vlan add interface=bridge1 name=vm-public vlan-id=150
/interface vlan add interface=bridge1 name=vm-private vlan-id=200

# Add gateway IPs:
/ip address add address=10.101.100.1/24 interface=mgmt
/ip address add address=10.101.150.1/24 interface=vm-public

# Add WAN IP:
/ip dhcp-client add interface=sfp-sfpplus8 disabled=no

# Add interfaces to lists
/interface list add name=WAN
/interface list add name=MGMT
/interface list add name=VLAN

/interface list member add list=WAN interface=sfp-sfpplus8
/interface list member add list=MGMT interface=mgmt
/interface list member add list=VLAN interface=mgmt
/interface list member add list=VLAN interface=pve-cluster-sync
/interface list member add list=VLAN interface=san-sync
/interface list member add list=VLAN interface=san-repl
/interface list member add list=VLAN interface=vm-public
/interface list member add list=VLAN interface=vm-private

# Firewall and NAT
/ip firewall filter
# Input chain
add chain=input action=accept connection-state=established,related
add chain=input action=accept in-interface-list=VLAN
add chain=input action=drop

# Forward chain
add action=fasttrack-connection chain=forward connection-state=established,related hw-offload=yes
add chain=forward action=accept connection-state=established,related
add chain=forward action=accept connection-state=new in-interface-list=VLAN out-interface-list=WAN
add chain=forward action=drop

# NAT
/ip firewall nat add chain=srcnat action=masquerade out-interface-list=WAN

# Enable VLAN filtering:
/interface bridge set bridge1 vlan-filtering=yes

# Set MTU and enable flow control:
/interface ethernet set [ find default-name=ether1 ] l2mtu=10218 mtu=10218 rx-flow-control=on tx-flow-control=on
/interface ethernet set [ find default-name=sfp-sfpplus1 ] l2mtu=10218 mtu=10218 rx-flow-control=on tx-flow-control=on
/interface ethernet set [ find default-name=sfp-sfpplus2 ] l2mtu=10218 mtu=10218 rx-flow-control=on tx-flow-control=on
/interface ethernet set [ find default-name=sfp-sfpplus3 ] rx-flow-control=on tx-flow-control=on
/interface ethernet set [ find default-name=sfp-sfpplus4 ] rx-flow-control=on tx-flow-control=on
/interface ethernet set [ find default-name=sfp-sfpplus5 ] rx-flow-control=on tx-flow-control=on
/interface ethernet set [ find default-name=sfp-sfpplus6 ] rx-flow-control=on tx-flow-control=on
/interface ethernet set [ find default-name=sfp-sfpplus7 ] rx-flow-control=on tx-flow-control=on
/interface ethernet set [ find default-name=sfp-sfpplus8 ] rx-flow-control=on tx-flow-control=on

# Enable L3 hardware offloading:
/interface/ethernet/switch/port set ether1 l3-hw-offloading=no
/interface/ethernet/switch/port set sfp-sfpplus8 l3-hw-offloading=no
/interface/ethernet/switch set 0 l3-hw-offloading=yes

# Lock down MAC server and Winbox to management interfaces:
/ip neighbor discovery-settings set discover-interface-list=MGMT
/tool mac-server set allowed-interface-list=MGMT
/tool mac-server mac-winbox set allowed-interface-list=MGMT
