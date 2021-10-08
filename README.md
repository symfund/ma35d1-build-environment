# ma35d1-build-environment
 an unattended bash script to setup build  environment in native Linux without docker inside for ma35d1

# Host OS
Ubuntu Desktop 20.04 LTS 64-bit

# Install
1. Before installing Ubuntu Desktop 20.04 LTS 64-bit, disconnect the computer from network
2. Install Ubuntu Desktop 20.04
3. Connect the computer to network
4. Fetch this script
5. Execute this script
  * $ chmod +x setup_ma35d1.sh
  * $ source setup_ma35d1.sh

Usually, due to unstable network connection, this script often is executed unsuccessfully. Reexcuting this script again and again can make the build passed, but that is not recommended.

If the script has synchronized the repository (repo sync --force-sync) without problem, following the below steps to make the build passed.
1. $ cd ~/Project/yocto
2. DISTRO=nvt-ma35d1-directfb MACHINE=ma35d1-evb source sources/init-build-env build
3. bitbake nvt-image-qt5

Do 'bitbake nvt-image-qt5' again and again until the final image is generated out!
