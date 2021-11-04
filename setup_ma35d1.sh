# !/bin/sh


# To run this script, 'source script'
# source setup_ma35d1.sh

# or in this way, 'dot script'
# . setup_ma35d1.sh


# Colors
# =========================================
# BLACK		0;30 DARK GRAY		1;30
# RED		0;31 LIGHT RED		1;31
# GREEN		0;32 LIGHT GREEN	1;32
# ORANGE	0;33 YELLOW		1;33
# BLUE		0;34 LIGHT		1;34
# PURPLE	0;35 LIGHT PURPLE	1;35
# CYAN		0;36 LIGHT CYAN		1;36
# LIGHTGRAY	0;37 WHITE		1;37

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'


script_name=$0
script_full_path=$(dirname "$0")

#echo "script name: $script_name"
#echo "full path: $script_full_path"


# Force uninstalling unnecessary packages to accelerate system update
sudo apt --purge remove firefox* thunderbird* libreoffice* rhythmbox*
sudo apt autoremove

sudo apt update 
sudo apt upgrade 
sudo apt autoremove

# System tools
SysTools="open-vm-tools openssh-server nfs-kernel-server net-tools curl git"
echo "System Tools Installing ..."

# Fast Installing
sudo apt install --yes $SysTools

# The following install way is considerably slow!
#for sw in $SysTools; do
#  echo "${RED}installing $sw ...${NC}"
#  sudo apt install --yes $sw 
#done

# Yocto standard tools
echo "Yocto Tools Installing ..."
YoctoTools="gawk wget git-core diffstat unzip texinfo gcc-multilib build-essential chrpath socat cpio python3 python3-pip python3-pexpect xz-utils debianutils iputils-ping python3-git python3-jinja2 libegl1-mesa libsdl1.2-dev pylint3 xterm python3-subunit mesa-common-dev"

# Fast Installing
sudo apt install --yes $YoctoTools

# The following install way is considerably slow!
#for sw in $YoctoTools; do
#  echo "${RED}installing $sw ...${NC}"
#  sudo apt install --yes $sw
#done


#echo "sleep 5 days ..."
#sleep 5d

# MA35D1 tools
echo "Ma35d1 Tools Installing ..."
# xvfb is required as recipe m4proj uses NuEclipse from command line to compile Eclipse-based sample projects
Ma35d1Tools="python autoconf automake cvs subversion flex bison u-boot-tools libssl-dev libncurses5-dev xvfb"

# Fast Installing
sudo apt install --yes $Ma35d1Tools

# The following install way is considerably slow!
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
until repo sync --force-sync 
do
  echo -e "${GREEN}repo sync failed, retry... ${NC}"
done

# default distro & machine
distro=nvt-ma35d1-directfb
machine=ma35d1-evb

echo -e "${YELLOW}Select which board to build ... i: IoT e: EVB s: SOM ${NC}" 
echo -e "${GREEN}Type 'i', 'e', or 's' ... default: e (EVB board selected)${NC}"

while [ true ]; do
  read -s -n 1 -t 15 k

  case $k in
    i* ) distro=nvt-ma35d1 machine=ma35d1-iot 
         break 
         ;;
    e* ) distro=nvt-ma35d1-directfb machine=ma35d1-evb 
         break 
         ;;
    s* ) distro=nvt-ma35d1 machine=ma35d1-som 
         break 
         ;;
    *  ) echo -e " ${RED}No board specified, EVB board selected by default. ${NC} " 
         break 
         ;;
  esac
  
done

echo -e "${YELLOW}DISTRO: $distro, MACHINE: $machine${NC}"
sleep 5s

# Now, begin build full functionality image for machine ma35d1-evb
DISTRO=$distro MACHINE=$machine source sources/init-build-env build

YP=$(pwd)/..

# Select image core-image-minimal nvt-image-qt5  
imagename=core-image-minimal

if [[ "$machine" == "ma35d1-evb" ]]; then
  imagename=nvt-image-qt5
fi

offline_build() {

  cd ${YP}/downloads/git2/github.com.OpenNuvoton.MA35D1_arm-trusted-firmware-v2.3.git/
  if [[ "$1" == "Y" ]]; then 
    sed -i 's/^SRCREV.*/SRCREV = "'$(git rev-parse HEAD)'"/' ${YP}/sources/meta-ma35d1/recipes-bsp/tf-a/tf-a-ma35d1_2.3.bb
  else
    sed -i 's/^SRCREV.*/SRCREV = "master"/' ${YP}/sources/meta-ma35d1/recipes-bsp/tf-a/tf-a-ma35d1_2.3.bb
  fi
  #cat ${YP}/sources/meta-ma35d1/recipes-bsp/tf-a/tf-a-ma35d1_2.3.bb

  cd ${YP}/downloads/git2/github.com.OpenNuvoton.MA35D1_linux-5.4.y.git/
  if [[ "$1" == "Y" ]]; then 
    sed -i 's/^SRCREV.*/SRCREV = "'$(git rev-parse HEAD)'"/' ${YP}/sources/meta-ma35d1/recipes-kernel/linux/linux-ma35d1_5.4.110.bb
  else
    sed -i 's/^SRCREV.*/SRCREV = "master"/' ${YP}/sources/meta-ma35d1/recipes-kernel/linux/linux-ma35d1_5.4.110.bb
  fi
  #cat ${YP}/sources/meta-ma35d1/recipes-kernel/linux/linux-ma35d1_5.4.110.bb

  cd ${YP}/downloads/git2/github.com.OpenNuvoton.MA35D1_NuWriter.git/
  if [[ "$1" == "Y" ]]; then 
    sed -i 's/^SRCREV.*/SRCREV = "'$(git rev-parse HEAD)'"/' ${YP}/sources/meta-ma35d1/recipes-devtools/python/python3-nuwriter_0.90.0.bb
  else
    sed -i 's/^SRCREV.*/SRCREV = "master"/' ${YP}/sources/meta-ma35d1/recipes-devtools/python/python3-nuwriter_0.90.0.bb
  fi
  #cat ${YP}/sources/meta-ma35d1/recipes-devtools/python/python3-nuwriter_0.90.0.bb

  cd ${YP}/downloads/git2/github.com.OpenNuvoton.MA35D1_optee_os-v3.9.0.git/
  if [[ "$1" == "Y" ]]; then 
    sed -i 's/^SRCREV.*/SRCREV = "'$(git rev-parse HEAD)'"/' ${YP}/sources/meta-ma35d1/recipes-security/optee/optee-os-ma35d1_3.9.0.bb
  else
    sed -i 's/^SRCREV.*/SRCREV = "'master'"/' ${YP}/sources/meta-ma35d1/recipes-security/optee/optee-os-ma35d1_3.9.0.bb
  fi
  #cat ${YP}/sources/meta-ma35d1/recipes-security/optee/optee-os-ma35d1_3.9.0.bb

  cd ${YP}/downloads/git2/github.com.OpenNuvoton.MA35D1_RTP_BSP.git/
  if [[ "$1" == "Y" ]]; then 
    sed -i 's/^SRCREV.*/SRCREV = "'$(git rev-parse HEAD)'"/' ${YP}/sources/meta-ma35d1/recipes-bsp/m4proj/m4proj_0.90.bb
  else
    sed -i 's/^SRCREV.*/SRCREV = "'master'"/' ${YP}/sources/meta-ma35d1/recipes-bsp/m4proj/m4proj_0.90.bb
  fi
  #cat ${YP}/sources/meta-ma35d1/recipes-bsp/m4proj/m4proj_0.90.bb

  cd ${YP}/downloads/git2/github.com.OpenNuvoton.MA35D1_u-boot-v2020.07.git/
  if [[ "$1" == "Y" ]]; then 
    sed -i 's/^SRCREV.*/SRCREV = "'$(git rev-parse HEAD)'"/' ${YP}/sources/meta-ma35d1/recipes-bsp/u-boot/u-boot-ma35d1_2020.07.bb
  else
    sed -i 's/^SRCREV.*/SRCREV = "'master'"/' ${YP}/sources/meta-ma35d1/recipes-bsp/u-boot/u-boot-ma35d1_2020.07.bb
  fi
  #cat ${YP}/sources/meta-ma35d1/recipes-bsp/u-boot/u-boot-ma35d1_2020.07.bb

  if grep -q "BB_NO_NETWORK" ${YP}/build/conf/local.conf; then
    #found 
    #echo -e "${RED}BB_NO_NETWORK found${NC}"
    if [[ "$1" == "N" ]]; then 
      sed -i 's/^BB_NO_NETWORK.*/BB_NO_NETWORK = "0"/' ${YP}/build/conf/local.conf
    else
      sed -i 's/^BB_NO_NETWORK.*/BB_NO_NETWORK = "1"/' ${YP}/build/conf/local.conf
    fi
  else
    #not found, append a line at the end of the file
    #echo -e "${RED}BB_NO_NETWORK not found${NC}"
    if [[ "$1" == "N" ]]; then
      echo 'BB_NO_NETWORK = "0"' >> ${YP}/build/conf/local.conf 
      #sed '$ a BB_NO_NETWORK = "0"' ${YP}/build/conf/local.conf
    else
      echo 'BB_NO_NETWORK = "1"' >> ${YP}/build/conf/local.conf
      #sed '$ a BB_NO_NETWORK = "1"' ${YP}/build/conf/local.conf
    fi
  fi

  #echo -e "${YELLOW}enable offline build in local.conf whether or not?${NC}"
  #cat ${YP}/build/conf/local.conf

  cd ${YP}/build

#  if [[ "$1" == "N" ]]; then 
#    bitbake u-boot-ma35d1 -c cleansstate 
#    bitbake m4proj -c cleansstate
#    bitbake linux-ma35d1 -c cleansstate
#  fi
}

# force offline build in case of bitbake always fetches code failed
if [[ -f ${YP}/build/build.done ]]; then

  echo -e "${YELLOW}force offline build?${NC}"
  echo -e "${GREEN}Type 'y', or 'n' ... default: y (force offline build)${NC}"

  while [ true ]; do
    read -s -n 1 -t 15 k

    case $k in
      y* ) echo -e "${RED}YES means that bitbake does not want to fetch the latest code${NC}" 
           sleep 5s
           offline_build "Y"
           break
           ;;
      n* ) echo -e "${RED}NO means that bitbake will fetch the latest code${NC}"
           sleep 5s
           offline_build "N"
           break 
           ;;
      *  ) offline_build "Y"
           break
           ;;
    esac

  done

fi

# Build image recipe
echo -e "${GREEN}start building $imagename ...${NC}"
until bitbake $imagename; do
  echo -e "${RED}bitbake $imagename failed. retrying ...${NC}"
  sleep 5s
done
echo -e "${GREEN}building $imagename succeeded!${NC}"
touch ${YP}/build/build.done

generate_sdk() {
  # SDK generation
  echo -e "${GREEN}start generating SDK ...${NC}"
  until bitbake $imagename -c populate_sdk; do
    echo -e "${RED}populate SDK for ${imagename} failed. retry...${NC}"
    sleep 5s
  done
  echo -e "${GREEN}generating SDK succeeded!${NC}"
}

if [ ! -f ${YP}/build/tmp-glibc/deploy/sdk/oecore-x86_64-aarch64-toolchain-5.5-dunfell.sh ]; then
  echo "uncomment to generate SDK"
  #generate_sdk
fi

# Offline build
echo -e "${YELLOW}CAUTION: offline build can accelerate the next time image generation, but maybe miss the important fixes if the SOC vendor updated the repositories!${NC}"
echo -e "${GREEN}Enable offline build? Type [y]es or [n]o ..., by default, always enable offline build!${NC}"

while [ true ]; do
  read -s -n 1 -t 15 k

  case $k in
    n* ) echo -e "${GREEN}disable offline build${NC}"
         offline_build "N"
         ;;
    y* ) echo -e "${GREEN}enable offline build${NC}"
         offline_build "Y"
         break
         ;;
    *  ) echo -e "${YELLOW}enable offline build automatically by default.${NC} "
         offline_build "N"
         break
         ;;
  esac

done

echo "All done. Press any key to continue..."

# devtool build-image $imagename
