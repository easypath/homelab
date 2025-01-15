# Starwind vSAN
Deploys vSAN CVM on Proxmox VE. 

> ***Refer to the official [setup guide](https://www.starwindsoftware.com/resource-library/starwind-virtual-san-vsan-configuration-guide-for-proxmox-virtual-environment-ve-kvm-vsan-deployed-as-a-controller-virtual-machine-cvm-using-web-ui/) for more info.***

## Prerequisites
### Licence key and image
Need to [register](https://www.starwindsoftware.com/starwind-virtual-san#download) to get free licence key and KVM image, links will be sent via email

### Enable IOMMU
- Enable IOMMU for PCIe passthrough, add `intel_iommu=on iommu=pt` to `GRUB_CMDLINE_LINUX_DEFAULT` line in `/etc/default/grub file`:
  ```shell
  GRUB_CMDLINE_LINUX_DEFAULT="quiet intel_iommu=on iommu=pt"
  ```
- Run `update-grub` and reboot host
- Confirm IOMMU is enabled: `cat /proc/cmdline`:
  ```shell
  # cat /proc/cmdline
  BOOT_IMAGE=/boot/vmlinuz-6.8.12-4-pve root=/dev/mapper/pve-root ro quiet intel_iommu=on iommu=pt
  ```

## Deployment notes
- Create new VM as per setup guide
  - Turn off memory ballooning
- Upload CVM disk image to Proxmox host
- Import disk image to VM:
  ```shell
  qm importdisk {VM_ID} /root/CVM.qcow2 local-lvm
  ```
- Run initial setup using web GUI:
  - Upload licence file
  - Set static IP for `mgmt` interface
  - Set hostname
  - Set admin credentials
- Add partner under *Appliances* section
- Configure network interfaces for *Data* and *Replication*:
  - Set all to automatically connect on boot
  - Set MTU 9000 for both
- Enable SSH server autostart, start service via GUI (Settings > Services)
- Repeat above steps for partner appliance
- Configure HA networking
- Create Storage Pool > Volume > LUN

### Witness node
- If want to deploy *Node majority* failover strategy, need an odd number of CVM nodes (minimum 3); required to prevent "split-brain" situations
  - Safer than *Heartbeat* failover, which only needs 2 nodes
- If don't have enough nodes/hardware, can deploy a CVM appliance as a "witness" node
  - Setup as a regular appliance, however does not contain any data
- Can run witness CVM node as a VM on another host

## Proxmox VE host iSCSI config
- Install following on each Proxmox VE host:
  ```shell
  apt-get install -y multipath-tools lsscsi
  ```
- Update iSCSI initiator name to match hostname:
  ```shell
  # cat /etc/iscsi/initiatorname.iscsi
  InitiatorName=iqn.1993-08.org.debian:pve-prod-a-01
  ```
- Edit `/etc/iscsi/iscsid.conf`, replace with config file in `configs` subfolder
- Create `/etc/multipath.conf` file with contents in `configs` subfolder 
- Run discovery:
  ```shell
  iscsiadm -m discovery -t st -p 10.101.107.5
  iscsiadm -m discovery -t st -p 10.101.107.6
  ```
- Login to iSCSI targets:
  ```shell
  iscsiadm -m node -T iqn.2008-08.com.starwindsoftware:10.101.100.5-vm-nvme-01 -p 10.101.107.5 -l
  iscsiadm -m node -T iqn.2008-08.com.starwindsoftware:10.101.100.6-vm-nvme-01 -p 10.101.107.6 -l
  ```
- Determine device ID of LUN, should show twice as mapped from two hosts:
  ```shell
  # lsscsi
  [8:0:0:0]    disk    STARWIND STARWIND         1     /dev/sdc 
  [9:0:0:0]    disk    STARWIND STARWIND         1     /dev/sdd 
  ```
- Get WWID of LUN:
  ```shell
  # /lib/udev/scsi_id -g -u -d /dev/sdc
  24fd45ffe08926d1b
  # /lib/udev/scsi_id -g -u -d /dev/sdd
  24fd45ffe08926d1b
  ```
- Add WWID to `/etc/multipath/wwids`:
  ```shell
  multipath -a 24fd45ffe08926d1b
  ```
- Restart multipath service:
  ```shell
  systemctl restart multipath-tools.service
  ```
- Check if multipathing is running correctly:
  ```shell
  # multipath -ll
  mpatha (24fd45ffe08926d1b) dm-9 STARWIND,STARWIND
  size=925G features='0' hwhandler='1 alua' wp=rw
  `-+- policy='round-robin 0' prio=50 status=active
    |- 8:0:0:0 sdc 8:32 active ready running
    `- 9:0:0:0 sdd 8:48 active ready running
  ```
- Run following:
  ```shell
  pvscan --cache
  ```
- Repeat above steps for each Proxmox VE host

### PV and VG creation
> ***Only do this on the first host!***
- Create PV and VG:
  ```shell
  pvcreate /dev/mapper/mpatha
  vgcreate vg-nvme-01 /dev/mapper/mpatha
  ```
- Login to Proxmox via Web and go to Datacenter > Storage:
  - Add new LVM storage
  - Set volume group to new VG created in prior step
  - Enable Shared checkbox. Click Add

### Passthrough physical disk to CVM
> *Refer to the [following steps](https://pve.proxmox.com/wiki/Passthrough_Physical_Disk_to_Virtual_Machine_(VM))*
- On the Proxmox VE host get ID of disk:
  ```shell
  # ls -al /dev/disk/by-id/
  ata-ST8000VN004-3CP101_SN123456
  ```
- Add to CVM VM:
  ```shell
  qm set 103 -scsi2 /dev/disk/by-id/ata-ST8000VN004-3CP101_SN123456
  ```
