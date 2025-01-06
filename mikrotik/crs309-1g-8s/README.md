# MikroTik CRS309-1G-8S
Config files for [CRS309-1G-8S+](https://mikrotik.com/product/crs309_1g_8s_in) network switch/router.

### Initial config
- Connect to POE/Boot port on device using Ethernet cable
- Assign static IP to client, i.e. `192.168.88.2/24`
- Log into device: [http://192.168.88.1](http://192.168.88.1)
- Factory default password is on sticker that came with device
- Reset password when prompted

### Manual firmware upgrade
- Download [updated firmware](https://mikrotik.com/product/crs309_1g_8s_in#fndtn-downloads) from MikroTik website
- In web GUI, navigate to Files > Upload
- Upload new firmware to root of filesystem
- Reboot via terminal:
  ```shell
  /system reboot
  ```
- Upgrade system board:
  - Navigate to Routing > RouterBOARD > Upgrade
  - Reboot device again

### Clear default config
```shell
/system reset-configuration no-defaults=yes skip-backup=yes
```
