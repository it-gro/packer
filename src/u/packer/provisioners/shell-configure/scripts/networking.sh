#!/bin/sh -eux

case "$PACKER_BUILDER_TYPE" in
virtualbox-iso|hyperv-iso)
    ubuntu_version="`lsb_release -r | awk '{print $2}'`";
    major_version="`echo $ubuntu_version | awk -F. '{print $1}'`";

    if [ "$ubuntu_version" = '17.10' ] || [ "$major_version" -ge "18" ]; then
    echo "Create netplan config for eth0"
    cat <<EOF >/etc/netplan/01-netcfg.yaml;
    network:
      version: 2
      ethernets:
        eth0:
          dhcp4: true
EOF
    else
      # Adding a 2 sec delay to the interface up, to make the dhclient happy
      echo "pre-up sleep 2" >> /etc/network/interfaces;
    fi

    if [ "$major_version" -ge "16" ]; then
      # Disable Predictable Network Interface names and use eth0
      sed -i 's/en[[:alnum:]]*/eth0/g' /etc/network/interfaces;
      sed -i 's/GRUB_CMDLINE_LINUX="\(.*\)"/GRUB_CMDLINE_LINUX="net.ifnames=0 biosdevname=0 \1"/g' /etc/default/grub;
      sed -i "/recordfail_broken=/{s/1/0/}" /etc/grub.d/00_header;
      update-grub;
    fi

    if [ "$major_version" -le "16" ]; then
      cat <<EOF >/boot/efi/startup.nsh;
FS0:
\EFI\ubuntu\grubx64.efi
EOF
    fi

    reboot
esac
