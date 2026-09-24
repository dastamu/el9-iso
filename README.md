# el9-iso
>Building own Enterprise Linux 9 ISO image

## Deps
### Method 1
```
@ EL 10
sudo dnf install createrepo_c xorriso
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
