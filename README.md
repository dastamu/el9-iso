# el9-iso
>Building own Enterprise Linux 9 ISO image

## Deps
### Method 1
```
@ EL 10 
sudo dnf install createrepo_c xorriso

wget -c https://yum.oracle.com/ISOS/OracleLinux/OL9/u8/x86_64/OracleLinux-R9-U8-x86_64-boot-uek.iso
wget -c https://yum.oracle.com/repo/OracleLinux/OL9/baseos/latest/x86_64/repodata/d8d30e7e5b6651973b362152f5791172184c285b2e1985dcb3df5cfebc6d726d-comps.xml

./build-el9-iso.sh
```
### Method 2
```
@ EL 10
sudo dnf install image-builder
```
## Build
```sh
image-builder list
sudo image-builder build image-installer --distro almalinux-9.8

sudo image-builder build image-installer --blueprint my-blueprint.toml
```
### Run
```sh
sudo dnf install qemu-kvm libvirt virt-install virt-viewer
sudo systemctl daemon-reload
sudo systemctl enable --now libvirtd

qemu-img create -f qcow2 vm-test.qcow2 16G
virt-install --name=VMTest --vcpus=2 --memory=4096 --disk path=vm-test.qcow2,size=16 --cdrom=el9-iso/generated.iso --os-variant=generic --network default --graphics vnc
```
