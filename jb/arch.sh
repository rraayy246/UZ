#!/usr/bin/env bash

# root 用户不建议使用此脚本
yh_g() {
 if [ "$USER" == "root"  ]; then
  echo "请先退出root用户，并登陆新创建的用户。"
  exit 1
 fi
}

# 判断显卡驱动
xk_pd() {
 if [ "$(lspci -vnn | grep -i "vga.*amd.*radeon")" ]; then
  gpu=xf86-video-amdgpu
 elif [ "$(lspci -vnn | grep -i "vga.*nvidia.*geforce")" ]; then
  gpu=xf86-video-nouveau
 fi
}

# 修改 pacman 配置
pac_pv() {
 # pacman 增加 multilib 源
 sudo sed -i "/^#\[multilib\]/,+1s/^#//g" /etc/pacman.conf
 # pacman 开启颜色
 sudo sed -i "/^#Color/s/^#//" /etc/pacman.conf
 # 加上 archlinuxcn 源
 if [ ! "$(grep "archlinuxcn" /etc/pacman.conf)" ]; then
  echo -e "[archlinuxcn]\nServer =  https://mirrors.tuna.tsinghua.edu.cn/archlinuxcn/\$arch" | sudo tee -a /etc/pacman.conf
  # 导入 GPG key
  sudo pacman -Syy --noconfirm archlinuxcn-keyring
 fi
}

# pacman 安装软件
pac_av() {
 # 更新系统并安装 btrfs 管理、网络管理器、tlp
 echo -e "\n" | sudo pacman -Syu btrfs-progs networkmanager tlp tlp-rdw
 # 声卡、触摸板、显卡驱动
 sudo pacman -S --noconfirm alsa-utils pulseaudio-alsa xf86-input-libinput ${gpu}
 # 繁简中日韩、emoji、Ubuntu字体
 sudo pacman -S --noconfirm noto-fonts-cjk noto-fonts-emoji ttf-ubuntu-font-family
 # 小企鹅输入法
 sudo pacman -S --noconfirm fcitx-im fcitx-rime fcitx-configtool
 # 显示服务器和 sway
 sudo pacman -S --noconfirm wayland sway swaybg swayidle swaylock xorg-server-xwayland
 # 图形挂件
 sudo pacman -S --noconfirm alacritty dmenu qt5-wayland
 # 播放控制、亮度控制、电源工具
 sudo pacman -S --noconfirm playerctl brightnessctl upower
 # 其他网络工具
 sudo pacman -S --noconfirm curl firefox firefox-i18n-zh-cn git wget yay
 # 必要工具
 sudo pacman -S --noconfirm neovim nnn p7zip zsh
 # 模糊搜索、图片
 sudo pacman -S --noconfirm fzf imv
 # mtp、蓝牙
 sudo pacman -S --noconfirm libmtp pulseaudio-bluetooth bluez-utils
 # 其他工具
 sudo pacman -S --noconfirm libreoffice-zh-CN nodejs tree vlc vim
 # steam
 #sudo pacman -S --noconfirm ttf-liberation wqy-zenhei steam
}

# 修改 yay 配置
yay_pv() {
 yay --aururl "https://aur.tuna.tsinghua.edu.cn" --save
}

# yay 安装软件
yay_av() {
 # 安装 ohmyzsh、jmtpfs
 yay -S --noconfirm oh-my-zsh-git jmtpfs
}

# 安装软件
rj_av() {
 xk_pd
 pac_pv
 pac_av
 yay_pv
 yay_av
}

# 设置 zsh
zsh_uv() {
 # 更改默认 shell 为 zsh
 sudo sed -i '/home/s/bash/zsh/' /etc/passwd
}

# 下载配置文件
pvwj_xz() {
 # 创建目录
 mkdir -p ~/{a,gz,xz,.config/{alacritty,fcitx,nvim,sway}}
 # 克隆 uz 仓库
 git clone https://github.com/rraayy246/uz ~/a/uz --depth 1
 # 移动配置文件
 pvwj=~/a/uz/pv/
 sudo cp ${pvwj}grub /etc/default/grub
 sudo cp ${pvwj}tlp /etc/tlp.conf
 cp ${pvwj}hjbl ~/.zprofile
 cp ${pvwj}zshenv ~/.zshenv
 cp ${pvwj}zshrc ~/.zshrc
 cp ${pvwj}sway ~/.config/sway/config
 cp ${pvwj}vtl.sh ~/.config/sway/vtl.sh
 cp ${pvwj}vsdr.yml ~/.config/alacritty/alacritty.yml
 cp ${pvwj}vim.vim ~/.config/nvim/init.vim
}

# 安装小鹤音形
xhyx_av() {
 # http://flypy.ys168.com/ 小鹤音形挂接第三方 小鹤音形Rime平台鼠须管for macOS.zip
 # 解压配置包
 7z x ${pvwj}flypy.7z
 cp -r ~/rime ~/.config/fcitx/
 # 删除压缩包
 rm -rf ~/rime ~/.config/fcitx/rime/default.yaml
 # 重新加载 fcitx 配置
 fcitx-remote -r
}

# 自启动管理
zqd_gl() {
 sudo systemctl enable --now {bluetooth,NetworkManager,NetworkManager-dispatcher,tlp}
 sudo systemctl disable dhcpcd
 sudo systemctl mask {systemd-rfkill.service,systemd-rfkill.socket}
}

# 创建交换文件
jhwj_ij() {
 sudo touch /swap # 创建空白文件
 sudo chattr +C /swap # 修改档案属性 不执行写入时复制（COW）
 sudo fallocate -l 4G /swap # 创建4G空洞文件
 sudo chmod 600 /swap # 修改文件读写执行权限
 sudo mkswap /swap # 格式化交换文件
 sudo swapon /swap # 启用交换文件
}

# 挂载交换文件
jhwj_gz() {
 echo "/swap swap swap defaults 0 0" | sudo tee -a /etc/fstab
 # 最大限度使用物理内存；生效
 echo "vm.swappiness = 1" | sudo tee /etc/sysctl.conf
 # 更新 sysctl 配置
 sudo sysctl -p
}

# 设置内核参数
nhcu_uv() {
 # 设置 resume 参数
 sudo sed -i "/^GRUB_CMDLINE_LINUX_DEFAULT/s/resume=\/dev\/\w*/resume=\/dev\/$(lsblk -l | awk '{ if($7=="/"){print $1} }')/" /etc/default/grub
 # 下载 btrfs_map_physical 工具
 wget -nv "https://raw.githubusercontent.com/osandov/osandov-linux/master/scripts/btrfs_map_physical.c" -P ~
 # 编译 btrfs_map_physical 工具
 gcc -O2 -o ~/btrfs_map_physical ~/btrfs_map_physical.c
 # 使用 btrfs_map_physical 提取 resume_offset 值
 offset=$(sudo ~/btrfs_map_physical /swap | awk '{ if($1=="0"){print $9} }')
 # 设置 resume_offset 参数
 sudo sed -i "/^GRUB_CMDLINE_LINUX_DEFAULT/s/resume_offset=[0-9]*/resume_offset=$((offset/4096))/" /etc/default/grub
 # 删除 btrfs_map_physical 工具
 rm ~/btrfs_map_physical*
 # 更新 grub 配置
 sudo grub-mkconfig -o /boot/grub/grub.cfg
}

# 设置 resume 钩子
gz_uv() {
 sudo sed -i "/^HOOKS/s/udev/& resume/" /etc/mkinitcpio.conf
 # 重新生成 initramfs 镜像
 sudo mkinitcpio -P
}

# 建立交换文件
jhwj_jl() {
 if [ ! -e "/swap" ]; then
  jhwj_ij
 fi

 if [ ! "$(grep "\/swap swap swap defaults 0 0" /etc/fstab)" ]; then
  jhwj_gz
 fi

 nhcu_uv

 if [ ! "$(grep "udev resume" /etc/mkinitcpio.conf)" ]; then
  gz_uv
 fi
}

# 设置 vim
vim_uv() {
 # 安装 vim-plug
 sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
 # 插件下载
 nvim +PlugInstall +qall
}

# uz 设置。
uz_uv() {
 if [ -d "$HOME/a/up/xt" ]; then
  ln -s ~/a/uz ~/uz
  cd ~/a/uz
  # 记忆账号密码
  git config credential.helper store
  git config --global user.email "rraayy246@gmail.com"
  git config --global user.name "ray"
  # 默认合并分支
  git config --global pull.rebase false
  cd
 fi
}

# 文字提醒
wztx() {
 echo -e "\n请手动执行 fcitx-configtool 修改输入法。"
}

# ======= 主程序 =======
vix_yx() {
 yh_g
 rj_av
 zsh_uv
 pvwj_xz
 xhyx_av
 zqd_gl
 jhwj_jl
 vim_uv
 uz_uv
 wztx
}

vix_yx
