# !/bin/sh

# Colors
# =========================================
# BLACK	0;30 DARK GRAY		1;30
# RED		0;31 LIGHT RED		1;31
# GREEN	0;32 LIGHT GREEN	1;32
# ORANGE	0;33 YELLOW		1;33
# BLUE		0;34 LIGHT		1;34
# PURPLE	0;35 LIGHT PURPLE	1;35
# CYAN		0;36 LIGHT CYAN	1;36
# LIGHTGRAY	0;37 WHITE		1;37

RED='\033[0;31m'
NC='\033[0m'

script_name=$0
script_full_path=$(dirname "$0")

echo "script name: $script_name"
echo "full path: $script_full_path"

sudo apt --purge remove firefox* thunderbird* libreoffice* rhythmbox*
sudo apt autoremove

sudo apt update 
sudo apt upgrade 
sudo apt autoremove

# System
# Speed Slow way
SysTools="open-vm-tools openssh-server nfs-kernel-server net-tools curl git"
echo "System Tools Installing ..."

# Fast Installing
sudo apt install --yes $SysTools

#for sw in $SysTools1; do
#  echo "${RED}installing $sw ...${NC}"
#  sudo apt install --yes $sw 
#done

# for Yocto
# Speed Slow
echo "Yocto Tools Installing ..."

YoctoTools="gawk wget git-core diffstat unzip texinfo gcc-multilib build-essential chrpath socat cpio python3 python3-pip python3-pexpect xz-utils debianutils iputils-ping python3-git python3-jinja2 libegl1-mesa libsdl1.2-dev pylint3 xterm python3-subunit mesa-common-dev"

# Fast Installing
sudo apt install --yes $YoctoTools

#for sw in $YoctoTools1; do
#  echo "${RED}installing $sw ...${NC}"
#  sudo apt install --yes $sw
#done


#echo "sleep 5 days ..."
#sleep 5d

# MA35D1
# Speed Slow
echo "Ma35d1 Tools Installing ..."
# xvfb is required as recipe m4proj uses NuEclipse from command line to compile Eclipse-based sample projects
Ma35d1Tools="python autoconf automake cvs subversion flex bison u-boot-tools libssl-dev libncurses5-dev xvfb"

# Fast Installing
sudo apt install --yes $Ma35d1Tools

#for sw in $Ma35d1Tools1; do
#  echo "${RED}installing $sw ...${NC}"
#  sudo apt install --yes $sw
#done

# uncomment to install Docker
# Docker 
# if [ ! -d ~/Projects/MA35D1_Docker_Script ]; then
#  mkdir -p ~/Projects/MA35D1_Docker_Script
#  git clone https://github.com/OpenNuvoton/MA35D1_Docker_Script.git ~/Projects/MA35D1_Docker_Script 
# fi

# Repo
if [ ! -f /usr/bin/repo ]; then
  echo "repo does not exist! Downloading repo from https://mirrors.tuna.tsinghua.edu.cn/git/git-rep"
  curl https://mirrors.tuna.tsinghua.edu.cn/git/git-repo > ~/repo
  if [ -f ~/repo ]; then
    chmod +x ~/repo
    sudo mv ~/repo /usr/bin/
  fi
fi

# Configure git
# test if a command outputs an empty string
# commands do not return values - they output them. You can capture this output by using command subsititution; e.g. $(ls -A)
if [ `git config user.email` ]; then

  strHeader=" ________________________________________________________"
  sizeStrHeader=${#strHeader}

  str2="| E-mail: $(git config user.email)"
  str3="| Name:   $(git config user.name)"
  sizeStr2=${#str2}
  sizeStr3=${#str3}

  echo 
  echo  " ________________________________________________________"
  echo  "|                                                       |"
  echo  "|                     Git Account                       |"
  echo  "|                                                       |"
  echo -n  "| E-mail: $(git config user.email)"

  start=1
  let end=sizeStrHeader-sizeStr2-1
  for ((i=$start; i<=$end; i++)); do echo -n " "; done
  echo "|" 

  echo -n  "| Name:   $(git config user.name)"
  
  let end=sizeStrHeader-sizeStr3-1
  for ((i=$start; i<=$end; i++)); do echo -n " "; done
  echo "|"

  echo  "|                                                       |"
  echo  "|_______________________________________________________|"
  echo 
  
else
  read -p "Enter Git user email: " email
  read -p "Enter Git user name: " fullname
  git config --global user.email $email
  git config --global user.name $fullname
fi

# Sleep
#echo "pause 10 seconds ..."
#sleep 5d

# Repo fetch
if [ ! -d ~/Projects/yocto ]; then
  mkdir -p ~/Projects/yocto
fi

if [ ! -d ~/Projects/yocto/source ]; then
  cd ~/Projects/yocto

  export REPO_URL='https://mirrors.tuna.tsinghua.edu.cn/git/git-repo'
  repo init -u git://github.com/OpenNuvoton/MA35D1_Yocto-v3.1.3.git -m meta-ma35d1/base/ma35d1.xml

fi

cd ~/Projects/yocto
repo sync
