# Mainline-Linux-on-MediaTek-Chromebook

# Create a root USB for dual booting
Prepare a host Linux computer. (Maybe install unbuntu in UTM in MacBook or a Linux shell in Chromebook)
These instructions are written for installing to a USB drive with the sda device, assuming no other USB drives are plugged in.
1. Get a root shell.
2. Start fdisk to create a GPT partition table:
fdisk /dev/sda
3. At the fdisk prompt:
Type g. This will create a new empty GPT partition table.
Write the partition table and exit by typing w.
4. Partition the micro SD card:
cgpt create /dev/sda
cgpt add -i 1 -t kernel -b 8192 -s 65536 -l Kernel -S 1 -T 5 -P 10 /dev/sda
5. To create the rootfs partition, we first need to calculate how big to make the partition using information from cgpt show. Look for the number under the start column for Sec GPT table which is 15633375 in this example:
localhost / # cgpt show /dev/sda
       start        size    part  contents
           0           1          PMBR
           1           1          Pri GPT header
        8192       65536      1   Label: "Kernel"
                                  Type: ChromeOS kernel
                                  UUID: E3DA8325-83E1-2C43-BA9D-8B29EFFA5BC4
                                  Attr: priority=10 tries=5 successful=1

    15633375          32          Sec GPT table
    15633407           1          Sec GPT header
6. Replace the xxxxx string in the following command with that number to create the root partition:
cgpt add -i 2 -t data -b 73728 -s `expr xxxxx - 73728` -l Root /dev/sda
7. Tell the system to refresh what it knows about the disk partitions:
partx -a /dev/sda
8. Format the root partition:
mkfs.ext4 /dev/sda2
9. Download mainline Linux, config for MediaTek Chromebook, and compile.
10. Make boot image and write to boot partition

wget https://github.com/chunkuang-hu/Mainline-Linux-on-MediaTek-Chromebook/tree/main/its_tool

cd its_tool

sh make_its.sh [linux out folder]

mkimage -D "-I dts -O dtb -p 2048" -f kernel.its vmlinux.uimg

dd if=/dev/zero of=bootloader.bin bs=512 count=1

echo "console=tty0 earlycon=uart8250,mmio32,0x11002000 init=/sbin/init root=/dev/sda2 rootwait  clk_ignore_unused debug loglevel=8 rw noinitrd" > cmdline

vbutil_kernel --pack vmlinux.kpart --version 1 --vmlinuz vmlinux.uimg --arch aarch64 --keyblock ../kernel.keyblock --signprivate ../kernel_data_key.vbprivk --config cmdline --bootloader bootloader.bin

dd if=./vmlinux.kpart of=/dev/sda1

11. Create rootfs: 

cd /tmp 

mkdir root 

mount /dev/sda2 root 

cd root 

11.1. Ubuntu base 

wget https://cdimage.ubuntu.com/ubuntu-base/releases/22.04/release/ubuntu-base-22.04-base-arm64.tar.gz 

tar zxfm  *.tar.gz 

11.2. chroot with network 

mount --bind /dev dev 

mount --bind /proc proc 

mount --bind /sys sys 

cp /etc/resolv.conf etc 

chroot . 

11.3. config password for 'root' 

passwd root 

11.4. install systemd, udev 

apt-get update 

apt-get install -y systemd 

apt-get install -y udev 

ln -s /lib/systemd/systemd /sbin/init 

11.5. Netowrk 

apt-get install -y iputils-ping 

apt-get install -y network-manager 

apt-get install -y netplan.io

vi /etc/netplan/99_config.yaml 

network:

  version: 2

  renderer: networkd

  ethernets:

    enx00e04cd25840:

      dhcp4: true
      
11.6. Exit chroot, umount rootfs

exit

cd ..

umount root

12. Flush data into USB.

sync


Reference:

[1] https://archlinuxarm.org/platforms/armv8/mediatek/acer-chromebook-r13

