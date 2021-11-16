# Setting up Yocto Build Environment for MA35D1 without Docker
 an unattended bash script to setup build  environment in native Linux without docker inside for ma35d1

# Host OS
Ubuntu Desktop 20.04.3 64-bit LTS

# Installing
1. Disconnect the computer from network before installing Ubuntu Desktop 20.04.3 64-bit LTS
2. Install Ubuntu Desktop 20.04.3 64-bit LTS
3. Connect the computer to network
4. Fetch this script
5. Execute this script, with or without argument **YP_DIR**. Without **YP_DIR**, script will fetch remote repositories into current directory, otherwise fetch code into **YP_DIR**

```bash
  $ source /path/to/setup_ma35d1.sh <YP_DIR>
```

# Selecting board
The MA35D1 yocto project supports three boards: **IoT**, **EVB**, and **SOM**.

When the script prompts to select board, just type **'i' for IoT, 'e' for EVB, and 's' for SOM**. By default, if user does not choose the board, EVB board will be selected. 

<table>
  <thead>
    <tr>
      <th>BOARD</th>
      <th>DISTRO</th>
      <th>MACHINE</th>
      <th>IMAGE</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td rowspan="2">EVB</td>
      <td rowspan="2">nvt-ma35d1-directfb</td>
      <td rowspan="2">ma35d1-evb</td>
      <td>nvt-image-qt5</td>
    </tr>
    <tr><td>core-image-minimal</td></tr>
   
   <tr>
      <td>IOT</td>
      <td>nvt-ma35d1</td>
      <td>ma35d1-iot</td>
      <td>core-image-minimal</td>
    </tr>
   
   <tr>
      <td>SOM</td>
      <td>nvt-ma35d1</td>
      <td>ma35d1-som</td>
      <td>core-image-minimal</td>
    </tr>
  
  </tbody>
</table>

# Selecting image
When EVB board is selected, there are two image choices **nvt-image-qt5** and **core-image-minimal** to be made.

# Generating SDK
Once the image is built out, the script will generate SDK for individual developer. Developers can use the standalone SDK toolchain on another machine to develop software with the same root filesystem content as the target device. 

**If extra features are enabled in image after the SDK generation is done, basically, the script should regenerate the SDK.**

Enabling features in image means changing the **EXTRA_IMAGE_FEATURES** and **IMAGE_INSTALL** in local build configuration file **${YP_DIR}/build/conf/local.conf**

# Offline build
Offline build can accelerate the next time image generation, provided that the bitbake completes its image recipe at least one time. However, if server has updated the repositories, bitbake will miss the latest important fixes. 

In another words, **disabling offline build** lead bitbake to fetch latest code.

To **force enabling offline build on another machine** that does not initialize the build environment at all, follow the subsequent steps 
1. prepare an empty directory **YP_DIR** (/path/to/yocto)
2. change current directory to **YP_DIR**
3. copy the downloaded dependency package **downloads.tar.gz** to this directory **YP_DIR**
4. extract the dependency package **downloads.tar.gz**
5. launch this script.

```
mkdir -p /path/to/yocto
cd /path/to/yocto
copy /path/to/downloads.tar.gz $PWD
tar xzvf downloads.tar.gz
source /path/to/setup_ma35d1.sh
```

To download all the dependency packages **downloads.tar.gz** without actually building image, issue the below command

```
$ bitbake core-image-minimal -c fetchall
```

# Building issues
Usually, due to unstable network connection, this script often is executed unsuccessfully. Reexcuting this script again and again can make the build passed, but that is not recommended.

If the script has synchronized the repository (repo sync --force-sync) without problem, open another terminal (press Ctrl + Alt + T or Ctrl + Shift + T) and follow the below steps to make the build passed.

**for EVB**
```bash
$ cd ~/Project/yocto
DISTRO=nvt-ma35d1-directfb MACHINE=ma35d1-evb source sources/init-build-env build
bitbake nvt-image-qt5
```

**for IoT**
```bash
$ cd ~/Project/yocto
DISTRO=nvt-ma35d1 MACHINE=ma35d1-iot source sources/init-build-env build
bitbake core-image-minimal
```

**for SOM**
```bash
$ cd ~/Project/yocto
DISTRO=nvt-ma35d1 MACHINE=ma35d1-som source sources/init-build-env build
bitbake core-image-minimal
```

Do 'bitbake nvt-image-qt5' again and again until the final image is generated out! Note that this script uses shell command 'until bitbake nvt-image-qt5' to ensure the image is built out.
