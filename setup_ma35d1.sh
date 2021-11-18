#! /bin/sh


# To run this script, perform the below command, with or without 'YP_DIR' argument.
# With 'YP_DIR', the script will fetch remote repositories into 'YP_DIR'.
# Without 'YP_DIR', script will fetch remote repositories into current directory.
#
# source /path/to/setup_ma35d1.sh <YP_DIR>



# default distro & machine
board=IOT
distro=nvt-ma35d1
machine=ma35d1-iot
imagename=core-image-minimal



# Colors

# ==================================================
# BLACK		0;30	DARK GRAY		1;30			
# RED		0;31	LIGHT RED		1;31
# GREEN		0;32	LIGHT GREEN		1;32
# ORANGE	0;33	YELLOW			1;33
# BLUE		0;34	LIGHT			1;34
# PURPLE	0;35	LIGHT PURPLE		1;35
# CYAN		0;36	LIGHT CYAN		1;36
# LIGHTGRAY	0;37	WHITE			1;37
# ==================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'



SCRIPT_NAME=$(realpath $0)
echo "script name: $SCRIPT_NAME" 

YP_DIR=""
CURDIR=""



generate_default_build_configuration() {

	if [ ! -f ${YP_DIR}/build/build.conf ]; then
		touch ${YP_DIR}/build/build.conf

		echo "SKIP_UNINSTALLING_TOOLS=false" >> ${YP_DIR}/build/build.conf
		echo "SKIP_SYSTEM_UPDATE=false" >> ${YP_DIR}/build/build.conf
		echo "SKIP_SYSTEM_UPGRADE=false" >> ${YP_DIR}/build/build.conf
		echo "SKIP_REPO_SYNC=false" >> ${YP_DIR}/build/build.conf
		echo "SKIP_SDK_GENERATION=false" >> ${YP_DIR}/build/build.conf
		echo "YP_INIT_DONE=false" >> ${YP_DIR}/build/build.conf
		echo "YP_BUILD_DONE=false" >> ${YP_DIR}/build/build.conf
		echo "ENABLE_OFFLINE_BUILD=false" >> ${YP_DIR}/build/build.conf
	fi
	
	source ${YP_DIR}/build/build.conf
}

whether_directory_empty_or_not() {
	if [ "$(ls -A ${CURDIR})" ]; then
		echo -e "${YELLOW}Current directory is not empty, wheter in a previous Yocto directory?${NC}"
		
		# script running in previous Yocto build directory, weak condition
		if [[ -f ${CURDIR}/bitbake-cookerdaemon.log ]]; then
			echo -e "${YELLOW}script is running in previous build directory${NC}"
			YP_DIR="${CURDIR}/.."
			generate_default_build_configuration
		else
			# ? YP_DIR/build>downloads,.repo>sources
			if [[ -d ${CURDIR}/build && -f ${CURDIR}/build/bitbake-cookerdaemon.log ]]; then
				echo -e "${YELLOW}script is running in upper level of the Yocto build directory${NC}"
				YP_DIR=${CURDIR}
				generate_default_build_configuration
			else
				YP_DIR=${CURDIR}
				echo -e "${GREEN}Yocto directory is ${YP_DIR}${NC}"
				mkdir -p ${YP_DIR}/build
				generate_default_build_configuration
			fi
		fi
		
	else
		echo -e "${YELLOW}Current directory is empty.${NC}"
		YP_DIR=${CURDIR}
		mkdir -p ${YP_DIR}/build
		generate_default_build_configuration
	fi
}

install_system_tools() {
	# chromium-browser openssh-server qtcreator net-tools wine open-vm-tools nfs-kernel-server 
	SysTools="curl git gitk"
	echo -e "${GREEN}Installing system tools ...${NC}"
	sudo apt install --yes $SysTools
}

install_yocto_tools() {
	echo -e "${GREEN}Installing Yocto tools ...${NC}"
	YoctoTools="gawk wget git-core diffstat unzip texinfo gcc-multilib build-essential chrpath socat cpio python3 python3-pip python3-pexpect xz-utils debianutils iputils-ping python3-git python3-jinja2 libegl1-mesa libsdl1.2-dev pylint3 xterm python3-subunit mesa-common-dev"
	sudo apt install --yes $YoctoTools
}

install_ma35d1_tools() {
	echo -e "${GREEN}Installing MA35D1 tools ...${NC}"
	# xvfb is required as recipe m4proj uses NuEclipse from command line to compile Eclipse-based sample projects
	Ma35d1Tools="python autoconf automake cvs subversion flex bison u-boot-tools libssl-dev libncurses5-dev xvfb"
	sudo apt install --yes $Ma35d1Tools
}

install_ma35d1_docer() {
	if [ ! -d ${YP_DIR}/MA35D1_Docker_Script ]; then
		mkdir -p ${YP_DIR}/MA35D1_Docker_Script
		git clone https://github.com/OpenNuvoton/MA35D1_Docker_Script.git ${YP_DIR}/MA35D1_Docker_Script 
	fi
}

install_repo() {
	if [ ! -f /usr/bin/repo ]; then
	  echo "repo does not exist! Downloading repo from https://mirrors.tuna.tsinghua.edu.cn/git/git-rep"
	  curl https://mirrors.tuna.tsinghua.edu.cn/git/git-repo > ~/repo
	  if [ -f ~/repo ]; then
	    chmod +x ~/repo
	    sudo mv ~/repo /usr/bin/
	  fi
	  echo -e "${GREEN}repo installation succeeded.${NC}"
	fi
}

init_repo() {
	if [ ! -d ${YP_DIR}/sources ]; then
		cd ${YP_DIR}

		export REPO_URL='https://mirrors.tuna.tsinghua.edu.cn/git/git-repo'
		
		until repo init -u git://github.com/OpenNuvoton/MA35D1_Yocto-v3.1.3.git -m meta-ma35d1/base/ma35d1.xml
		do
			echo -e "${RED}repo init failed! retrying ...${NC}"
		done
		
		echo -e "${GREEN}repo initialized successfully.${NC}"
		sed -i 's/^YP_INIT_DONE.*/YP_INIT_DONE=true/' ${YP_DIR}/build/build.conf
	else
		echo -e "${YELLOW}Migrating offline build to another machine${NC}"
		sed -i 's/^YP_INIT_DONE.*/YP_INIT_DONE=true/' ${YP_DIR}/build/build.conf
	fi
}

sync_repo() {
	cd ${YP_DIR}

	# offline build enabled?
	if [[ "$ENABLE_OFFLINE_BUILD" == false ]]; then
		if [[ "$SKIP_REPO_SYNC" == false ]]; then
			until repo sync --force-sync 
			do
				echo -e "${RED}repo sync failed, retrying ... ${NC}"

				if [[ -d ${YP_DIR}/sources ]]; then
					echo -e "${RED}The script detects that repo has completed the synchronization ever, skips sync this time.${NC}" 
					break
				fi
			done
			echo -e "${YELLOW}repo sync succeeded.${NC}"
		else
			echo -e "${YELLOW}It makes no sense skipping 'repo sync' with offline build disabled. 'SKIP_REPO_SYNC=true' should not reach here.${NC}"
			echo -e "${YELLOW}However, user wants to skip repo sync temporarily.${NC}"
		fi
	fi
}

configure_git_account() {

	# Configure git
	# test if a command outputs an empty string
	# commands do not return values - they output them. You can capture this output by using command subsititution; e.g. $(ls -A)
	if [ $(git config user.email) ]; then
	
	  str_header=" ________________________________________________________"
	  strlen_header=${#str_header}

	  str_mail="| E-mail: $(git config user.email)"
	  str_name="| Name:   $(git config user.name)"
	  strlen_mail=${#str_mail}
	  strlen_name=${#str_name}

	  echo 
	  echo  " ________________________________________________________"
	  echo  "|                                                       |"
	  echo  "|                     Git Account                       |"
	  echo  "|                                                       |"
	  echo -n  "| E-mail: $(git config user.email)"

	  start=1
	  let end=strlen_header-strlen_mail-1
	  for ((i=$start; i<=$end; i++)); do echo -n " "; done
	  echo "|" 

	  echo -n  "| Name:   $(git config user.name)"
	  
	  let end=strlen_header-strlen_name-1
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
}

select_machine() {
	# If exists the local build configuration file local.conf, read machine from that

	echo -e "${YELLOW}Select which machine to be built... SOM or SOM-1GB?${NC}" 
	echo -e "${GREEN}Type '1' for SOM-1GB, others for SOM. default: [ 0 ], SOM will be selected${NC}"

	while [ true ];
	do
		read -s -n 1 -t 15 k

		case $k in
			1* )
				machine=ma35d1-som-1gb
				echo -e "${GREEN}SOM 1GB machine selected!${NC}"
				break 
				;;
			0* )
				machine=ma35d1-som
				echo -e "${GREEN}SOM machine selected!${NC}"
				break 
				;;
			*  )
				machine=ma35d1-som
				echo -e " ${RED}No machine specified, machine SOM selected by default. ${NC} " 
				break 
				;;
		esac

	done
}

select_image() {
	# If exists the local build configuration file local.conf, read image name from that

	echo -e "${YELLOW}Select which image to be built... nvt-image-qt5 or core-image-minimal?${NC}"
	echo -e "${GREEN}Type 'n' for nvt-image-qt5, 'c' for core-image-minimal. default: [ n ], nvt-image-qt5 will be selected${NC}"

	while [ true ];
	do
		read -s -n 1 -t 15 k

		case $k in
			n* )
				imagename=nvt-image-qt5
				echo -e "${GREEN}nvt-image-qt5 image selected!${NC}"
				break 
				;;
			c* )
				imagename=core-image-minimal
				echo -e "${GREEN}core-image-minimal image selected!${NC}"
				break 
				;;
			*  )
				imagename=core-image-minimal
				echo -e " ${RED}No image specified, core-image-minimal selected by default. ${NC} " 
				break 
				;;
		esac

	done
}

select_board() {

	# If exists the local build configuration file local.conf, read board from that

	echo -e "${YELLOW}Select which board to build ... i: IoT e: EVB s: SOM ${NC}" 
	echo -e "${GREEN}Type 'i', 'e', or 's' ... default: [ i ] IOT board will be selected${NC}"

	while [ true ];
	do
		read -s -n 1 -t 15 k

		case $k in
			i* )
				board=IOT distro=nvt-ma35d1 machine=ma35d1-iot 
				break 
				;;
			e* )
				board=EVB distro=nvt-ma35d1-directfb machine=ma35d1-evb 
				break 
				;;
			s* )
				board=SOM distro=nvt-ma35d1 machine=ma35d1-som 
				break 
				;;
			*  )
				echo -e " ${RED}No board specified, ${machine} board selected by default. ${NC} " 
				break 
				;;
		esac

	done
	
	if [[ "$board" == "EVB" ]]; then
  		select_image
	fi
	
	if [[ "$board" == "SOM" ]]; then
  		select_machine
	fi
}

setup_build_environment() {

	select_board
	
	cd ${YP_DIR}
	DISTRO=$distro MACHINE=$machine source sources/init-build-env build

}

build_image_recipe() {
	echo -e "${GREEN}start building $imagename ...${NC}"
	
	until bitbake $imagename; do
		echo -e "${RED}bitbake $imagename failed. retrying ...${NC}"
		echo -e "${YELLOW}bitbake do_fetch failed? offline build enabled? Hah Hah! hnnn, got it!!!${NC}"
		sleep 5s
	done
	
	echo -e "${GREEN}building $imagename succeeded!${NC}"
	sed -i 's/^YP_BUILD_DONE.*/YP_BUILD_DONE=true/' ${YP_DIR}/build/build.conf
}

generate_sdk() {

	# [ ! -f ${YP_DIR}/build/tmp-glibc/deploy/sdk/oecore-x86_64-aarch64-toolchain-5.5-dunfell.sh ]

	if [ "$SKIP_SDK_GENERATION" == false ]; then
		echo -e "${GREEN}start generating SDK ...${NC}"
		until bitbake $imagename -c populate_sdk; do
			echo -e "${RED}populate SDK for ${imagename} failed. retry...${NC}"
			sleep 5s
		done
		echo -e "${GREEN}generating SDK succeeded!${NC}"
	fi
}

uninstall_tools() {
	if [[ "$SKIP_UNINSTALLING_TOOLS" == false ]]; then
		# Force uninstalling unnecessary packages to accelerate system update
		sudo apt --purge remove firefox* thunderbird* libreoffice* rhythmbox*
		sed -i 's/^SKIP_UNINSTALLING_TOOLS.*/SKIP_UNINSTALLING_TOOLS=true/' ${YP_DIR}/build/build.conf
	fi
}

system_update() {
	if [[ "$SKIP_SYSTEM_UPDATE" == false ]]; then
		sudo apt update
		sed -i 's/^SKIP_SYSTEM_UPDATE.*/SKIP_SYSTEM_UPDATE=true/' ${YP_DIR}/build/build.conf 
	fi
}

system_upgrade() {
	if [[ "$SKIP_SYSTEM_UPGRADE" == false ]]; then
		sudo apt upgrade
		sed -i 's/^SKIP_SYSTEM_UPGRADE.*/SKIP_SYSTEM_UPGRADE=true/' ${YP_DIR}/build/build.conf 
	fi
}

enable_offline_build() {

	declare -A ASSOC_ARRAY_REPO_RECP 

	ARM_TRUSTED_FIRMWARE_REPO="${YP_DIR}/downloads/git2/github.com.OpenNuvoton.MA35D1_arm-trusted-firmware-v2.3.git"
	ARM_TRUSTED_FIRMWARE_RECP="${YP_DIR}/sources/meta-ma35d1/recipes-bsp/tf-a/tf-a-ma35d1_2.3.bb"
	ASSOC_ARRAY_REPO_RECP[$ARM_TRUSTED_FIRMWARE_REPO]=$ARM_TRUSTED_FIRMWARE_RECP

	LINUX_REPO="${YP_DIR}/downloads/git2/github.com.OpenNuvoton.MA35D1_linux-5.4.y.git"
	LINUX_RECP="${YP_DIR}/sources/meta-ma35d1/recipes-kernel/linux/linux-ma35d1_5.4.110.bb"
	ASSOC_ARRAY_REPO_RECP[$LINUX_REPO]=$LINUX_RECP

	NUWRITER_REPO="${YP_DIR}/downloads/git2/github.com.OpenNuvoton.MA35D1_NuWriter.git"
	NUWRITER_RECP="${YP_DIR}/sources/meta-ma35d1/recipes-devtools/python/python3-nuwriter_0.90.0.bb"
	ASSOC_ARRAY_REPO_RECP[$NUWRITER_REPO]=$NUWRITER_RECP 

	OPTEE_REPO="${YP_DIR}/downloads/git2/github.com.OpenNuvoton.MA35D1_optee_os-v3.9.0.git"
	OPTEE_RECP="${YP_DIR}/sources/meta-ma35d1/recipes-security/optee/optee-os-ma35d1_3.9.0.bb"
	ASSOC_ARRAY_REPO_RECP[$OPTEE_REPO]=$OPTEE_RECP 

	M4PROJ_REPO="${YP_DIR}/downloads/git2/github.com.OpenNuvoton.MA35D1_RTP_BSP.git"
	M4PROJ_RECP="${YP_DIR}/sources/meta-ma35d1/recipes-bsp/m4proj/m4proj_0.90.bb"
	ASSOC_ARRAY_REPO_RECP[$M4PROJ_REPO]=$M4PROJ_RECP

	UBOOT_REPO="${YP_DIR}/downloads/git2/github.com.OpenNuvoton.MA35D1_u-boot-v2020.07.git"
	UBOOT_RECP="${YP_DIR}/sources/meta-ma35d1/recipes-bsp/u-boot/u-boot-ma35d1_2020.07.bb"
	ASSOC_ARRAY_REPO_RECP[$UBOOT_REPO]=$UBOOT_RECP

	for repo in "${!ASSOC_ARRAY_REPO_RECP[@]}"
	do
		if [[ "$ENABLE_OFFLINE_BUILD" == true ]]; then
			sed -i 's/^SRCREV.*/SRCREV = "'$(git -C ${repo} rev-parse HEAD)'"/' ${ASSOC_ARRAY_REPO_RECP[$repo]}
		else
			sed -i 's/^SRCREV.*/SRCREV = "master"/' ${ASSOC_ARRAY_REPO_RECP[$repo]} 
		fi
	done


	if grep -q "BB_NO_NETWORK" ${YP_DIR}/build/conf/local.conf; then 
		if [[ "$ENABLE_OFFLINE_BUILD" == false ]]; then 
			sed -i 's/^BB_NO_NETWORK.*/BB_NO_NETWORK = "0"/' ${YP_DIR}/build/conf/local.conf
		else
			sed -i 's/^BB_NO_NETWORK.*/BB_NO_NETWORK = "1"/' ${YP_DIR}/build/conf/local.conf
		fi
	else
		if [[ "$ENABLE_OFFLINE_BUILD" == false ]]; then
			sed -i -e '$aBB_NO_NETWORK = "0"' ${YP_DIR}/build/conf/local.conf
		else
			sed -i -e '$aBB_NO_NETWORK = "1"' ${YP_DIR}/build/conf/local.conf
		fi
	fi

	cd ${YP_DIR}/build

	#  if [[ "$1" == "N" ]]; then 
	#    bitbake u-boot-ma35d1 -c cleansstate 
	#    bitbake m4proj -c cleansstate
	#    bitbake linux-ma35d1 -c cleansstate
	#  fi
}

confirm_offline_build() {

	if [[ "$YP_BUILD_DONE" == true ]]; then
		echo -e "${GREEN}script detects that Yocto has completed image build ever, thus enabling offline build can accelerate image build."
		echo -e "${YELLOW}Disabling offline build? [Y]es/[n]o, default: NO, disabling offline build means bitbake will fetch the latest code."
		
		while [ true ];
		do
			read -s -n 1 -t 15 k

			if [[ "$k" == "Y" || "$k" == "y" ]]; then
				ENABLE_OFFLINE_BUILD=false
				sed -i 's/^ENABLE_OFFLINE_BUILD.*/ENABLE_OFFLINE_BUILD=false/' ${YP_DIR}/build/build.conf
				echo -e "${GREEN}offline build disabled${NC}"
				break;
			else
				ENABLE_OFFLINE_BUILD=true
				sed -i 's/^ENABLE_OFFLINE_BUILD.*/ENABLE_OFFLINE_BUILD=true/' ${YP_DIR}/build/build.conf
				echo -e "${GREEN}offline build enabled${NC}"
				break;
			fi

			echo -e "${GREEN}no answer for confirming offline build, offline build enabled${NC}"
			break
			

		done
		
		enable_offline_build
	else
		if [[ -d ${YP_DIR}/downloads ]]; then
			echo -e "${YELLOW}force enabling offline build silently${NC}"
			ENABLE_OFFLINE_BUILD=true
			sed -i 's/^ENABLE_OFFLINE_BUILD.*/ENABLE_OFFLINE_BUILD=true/' ${YP_DIR}/build/build.conf
			enable_offline_build
		fi

	fi
}



if [ "$1" ]; then
	echo -e "${RED}Yocto directory presented explicitly, that means the script will create it${NC}"
	
	if [[ -d "$1" ]]; then
		echo -e "${YELLOW}but script detects the directory is already existing!, then it will fetch Yocto into this directory: $1.${NC}"
		CURDIR="$1"
		whether_directory_empty_or_not
	else
		# OK
		YP_DIR="$1"
		echo -e "${GREEN}script creates the Yocto directory: ${YP_DIR}.${NC}"
		mkdir -p ${YP_DIR} ${YP_DIR}/build
		generate_default_build_configuration
	fi
	
else
	CURDIR=$(dirname $SCRIPT_NAME)
	echo -e "${YELLOW}Yocto directory not presented, implicitly means that script will fetch Yocto into current directory: $CURDIR${NC}"
	whether_directory_empty_or_not
fi



if [[ "$YP_INIT_DONE" == false ]]; then
	echo -e "${YELLOW}Yocto is not yet initialized${NC}"
		
	uninstall_tools
	system_update
	system_upgrade
	install_system_tools
	install_yocto_tools
	install_ma35d1_tools
	#install_ma35d1_docer
	install_repo
	configure_git_account
	init_repo
	sync_repo
	setup_build_environment
	confirm_offline_build
	build_image_recipe
	generate_sdk
	
else
	# if repo sync succeeded and change revision to a new higher number, but bitbake do_fetched failed subsequenced
	sync_repo
	setup_build_environment
	confirm_offline_build
	build_image_recipe
	generate_sdk
fi



# devtool build-image $imagename

