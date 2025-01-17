# FortiGate VM
### Deploying on Proxmox VE notes
- VM image: `FGT_VM64_KVM-v7.4.6.M-build2726-FORTINET.out.kvm.zip (95.2 MB)`
- SCP image to PVE host
- Create blank VM with no disk
- SSH to host, import disk:
  ```shell
  qm disk import 100 fortios.qcow2 local-lvm
  ```

### Initial config
- Select Trial, sign into FortiCloud
- Disable auto updates
- Set static IP for `mgmt` interface:
  ```shell
  config system interface 
  edit port1
  set mode static
  set ip 10.101.100.1/24
  end
  ```
- Set timezone to UTC

### NTP
- Enable local NTP server:
  - Navigate to *System > Settings*, check *Setup device as local NTP server*
  - Select interfaces to listen on
- Enable NTP on all DHCP servers

### References
- [Deploying a FortiGate-VM into Proxmox](https://docs.fortinet.com/document/fortigate-private-cloud/7.6.0/proxmox-administration-guide/37920)
- [Virtualizing Fortigate firewall on Proxmox](https://www.youtube.com/watch?v=nY7CVtsTLro)