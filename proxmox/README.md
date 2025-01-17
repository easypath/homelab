# Proxmox VE
### Initial config
- Default address: [https://10.101.100.10:8006](https://10.101.100.10:8006)

### Host network config
- Replace contents of `/etc/network/interfaces` with sample file located in `configs` subfolder
  - Update interface names and addresses
- Reload network config:
  ```shell
  ifreload -a
    ```

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
- Run on each node to add to cluster:
  ```shell
  # pve-prod-a-02
  pvecm add 10.101.105.10 --link0 10.101.105.20 --fingerprint 'AB:92:22:48:1E:F2:29:75:9B:6A:98:45:5E:B1:5D:59:BF:64:39:E6:39:B1:EC:AB:99:FE:AF:4D:57:2E:8D:D4'
  # pve-prod-a-03
  pvecm add 10.101.105.10 --link0 10.101.105.30 --fingerprint 'AB:92:22:48:1E:F2:29:75:9B:6A:98:45:5E:B1:5D:59:BF:64:39:E6:39:B1:EC:AB:99:FE:AF:4D:57:2E:8D:D4'
  ```
  - *Note: fingerprint is SSH fingerprint of first node*
- Check cluster status:
  ```shell
  systemctl status corosync
  pvecm status
  ```
- Navigate to Datacenter > Options > HA Settings, change shutdown policy to `migrate`
- Configure HA groups and add resources

### NTP config
- Configure local NTP server:
  ```shell
  echo 'server 10.101.100.1 iburst' > /etc/chrony/sources.d/local-ntp-server.sources
  chronyc reload sources
  ```

### References
- [Proxmox VE How To Setup High Availability](https://youtu.be/hWNm4hYejqU?si=PkmhRwICdRrTjhGy)