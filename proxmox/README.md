# Proxmox
### Initial config
- Default address: [https://10.101.100.10:8006](https://10.101.100.10:8006)

### Host network config
- Change host IP:
  - Edit `/etc/network/interfaces`
  - Edit `/etc/hosts`
  - Reload network config:
    ```shell
    ifreload -a
    ```
- Add bridge for VLAN trunk:
  - Create new Linux bridge device, `vmbr1`, bound to VM interface (`enp1s0`)
  - Check "VLAN aware"
  - For VM, select `vmbr1` and add VLAN tag to network interface
- *Note: when adding VLAN interfaces to host, configure VLAN on interface with least abstraction layers from physical NIC ([more info](https://pve.proxmox.com/wiki/Network_Configuration#sysadmin_network_vlan))*

### Enable host updates
- Update to Proxmox no-subscription repo:
  ```shell
  echo -e "\n# Proxmox VE pve-no-subscription repository provided by proxmox.com,\n# NOT recommended for production use\ndeb http://download.proxmox.com/debian/pve bookworm pve-no-subscription" >> /etc/apt/sources.list
  ```
- Disable following Proxmox Enterprise repos (via GUI or comment out contents of files):
  - `/etc/apt/sources.list.d/pve-enterprise.list`
  - `/etc/apt/sources.list.d/ceph.list`

### HA cluster
- Create cluster on first node:
  ```shell
  pvecm create pvecluster-prod --link0 10.101.105.10
  ```
- Add nodes:
  ```shell
  pvecm add 10.101.105.10 --link0 10.101.105.20 --fingerprint 'AB:92:22:48:1E:F2:29:75:9B:6A:98:45:5E:B1:5D:59:BF:64:39:E6:39:B1:EC:AB:99:FE:AF:4D:57:2E:8D:D4'
  pvecm add 10.101.105.10 --link0 10.101.105.30 --fingerprint 'AB:92:22:48:1E:F2:29:75:9B:6A:98:45:5E:B1:5D:59:BF:64:39:E6:39:B1:EC:AB:99:FE:AF:4D:57:2E:8D:D4'
  ```
  - *Note: fingerprint is SSH fingerprint of first node*
- Check cluster status:
  ```shell
  systemctl status corosync
  pvecm status
  ```
