# Arch Linux (UEFI with GPT) 安装

## 下载 Arch Linux 镜像

<https://www.archlinux.org/download/>

`md5 archlinux.iso` 验证镜像完整性

将输出和下载页面提供的 md5 值对比一下，看看是否一致，不一致则不要继续安装，换个节点重新下载直到一致为止。

## 镜像写入 U 盘

windows 用户请使用 rufus

`sudo fdisk -l` 查看设备

`sudo umount /dev/sdx*` /dev/sdx是我的U盘设备，umount U盘。

`sudo mkfs.vfat /dev/sdx –I` 格式化U盘

`dd bs=4M if=/path/to/archlinux.iso of=/dev/sdx status=progress && sync` 镜像写入 U 盘

## 从 U 盘启动 Arch live 环境

在 UEFI BIOS 中设置启动磁盘为刚刚写入 Arch 系统的 U 盘。

进入 U 盘的启动引导程序后，选择第一项：Arch Linux archiso x86_64 UEFI CD

## 检查网络时间

`ip link` 查看连接

对于有线网络，安装镜像启动的时候，默认会启动 dhcpcd，如果没有启动，可以手动启动：`dhcpcd`

无线网络请使用 `wifi-menu`

`ping www.163.com` 测试网络是否可用，安装过程中需要用到网络

`timedatectl set-ntp true` 更新系统时间

## 磁盘分区

`fdisk -l` 查看磁盘设备

`fdisk /dev/nvme0n1` 新建分区表


我要把系统安装在nvme0n1这个硬盘中

nvme0n1是固态硬盘，sda是普通硬盘

1. 输入 `g`，新建 GPT 分区表
2. 输入 `w`，保存修改，这个操作会抹掉磁盘所有数据，慎重

`fdisk /dev/nvme0n1` 分区创建

1. 新建 EFI System 分区
    1. 输入 `n`
    2. 选择分区区号，直接 `Enter`，使用默认值，fdisk 会自动递增分区号
    3. 分区开始扇区号，直接 `Enter`，使用默认值
    4. 分区结束扇区号，输入 `+512M`（推荐大小）
    5. 输入 `t` 修改刚刚创建的分区类型
    6. 输入 `1`，使用 EFI System 类型
2. 新建 Linux root (x86-64) 分区
    1. 输入 `n`
    2. 选择分区区号，直接 `Enter`，使用默认值，fdisk 会自动递增分区号
    3. 分区开始扇区号，直接 `Enter`，使用默认值
    4. 分区结束扇区号，直接 `Enter`，选择全部剩余空间
    5. 输入 `t` 修改分区类型
    6. 选择分区区号，直接 `Enter`，选择刚创建的分区
    7. 输入 `24`，使用 Linux root (x86-64) 类型
3. 保存新建的分区
    1. 输入 `w`

## 磁盘格式化

`mkfs.fat -F32 /dev/nvme0n1p1` 格式化 EFI System 分区为 fat32 格式

如果格式化失败，可能是磁盘设备存在 Device Mapper：`dmsetup status` 显示 dm 状态 `dmsetup remove <dev-id>` 删除 dm

`mkfs.btrfs -f /dev/nvme0n1p2` 格式化 Linux root 分区为 brtfs 格式

## 挂载文件系统

```shell
mount /dev/nvme0n1p2 /mnt
mkdir /mnt/boot
mount /dev/nvme0n1p1 /mnt/boot
```

`vim /etc/pacman.d/mirrorlist` 配置 pacman mirror 镜像源

找到标有China的镜像源，命令模式下按下 `dd` 可以剪切光标下的行，按 `gg` 回到文件首，按 `P`（注意是大写的）将行粘贴到文件最前面的位置（优先级最高）。

最后记得用 `:wq` 命令保存文件并退出。

`pacman -Syy` 更新mirror数据库

`pacstrap /mnt base base-devel linux linux-firmware` 安装 Arch 和 Package Group

`genfstab -U /mnt >> /mnt/etc/fstab` 生成 fstab 文件

检查fstab文件 `cat /mnt/etc/fstab`

`arch-chroot /mnt` 切换至安装好的 Arch

## 本地化

`pacman -S amd-ucode btrfs-progs dhcpcd efibootmgr grub os-prober vim` 安装必要软件

amd-ucode 为 AMD CPU 微码，使用 Intel CPU 者替换成 intel-ucode

因为本次安装使用btrfs文件系统，所以要安装 btrfs-progs。

`ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime` 设置时区

`hwclock --systohc --utc` 设置时间标准为UTC

`vim /etc/locale.gen` 修改本地化信息

移除 en_US.UTF-8 UTF-8 、zh_CN.UTF-8 UTF-8前面的 # 后保存。

按 `x` 删除当前光标所在处的字符，按 `u` 撤消最后执行的命令，`:wq` 命令保存文件并退出。

`locale-gen` 生成本地化信息

`echo LANG=en_US.UTF-8 > /etc/locale.conf` 将系统 locale 设置为en_US.UTF-8

`echo 主机名 > /etc/hostname` 修改主机名

`vim /etc/hosts` 编辑hosts

加入以下字串

```shell
127.0.0.1	localhost
::1		localhost
127.0.1.1	主机名.localdomain 主机名
```

按 `i` 切换到输入模式，按 `ESC` 回到命令模式，`:wq` 命令保存文件并退出。

`systemctl enable dhcpcd` 设置dhcpcd自启动

`passwd` 修改root密码

安装GRUB引导程序

```shell
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=grub
grub-mkconfig -o /boot/grub/grub.cfg
```

检查grub文件 `vim /boot/grub/grub.cfg`

重新启动

```shell
exit  #退出 chroot 环境
umount -R /mnt #手动卸载被挂载的分区
reboot
```

## 搭建桌面环境

以root登入

`useradd -m 用户名` 创建新用户

`passwd 用户名` 设置登陆密码

`vim /etc/sudoers` 编辑sudo权限

复制一行root ALL=(ALL) ALL, 并替换其中的root为新用户名，`:wq!` 强制保存并退出。

`exit` 退出root用户，并登陆新创建的用户。

## 快速配置i3

```shell
sudo pacman -S curl
sh -c "$(curl -fsSL https://github.com/rraayy246/UZ/raw/master/arch.sh)"
```