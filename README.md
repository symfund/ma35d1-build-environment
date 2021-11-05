# Setting up Yocto Build Environment for MA35D1 without Docker
 an unattended bash script to setup build  environment in native Linux without docker inside for ma35d1

# Host OS
Ubuntu 20.04.3 LTS 64-bit Desktop

# Installing
1. Before installing Ubuntu Desktop 20.04 LTS 64-bit (https://mirror.umd.edu/ubuntu-iso/20.04.3/ubuntu-20.04.3-desktop-amd64.iso), disconnect the computer from network
2. Install Ubuntu Desktop 20.04
3. Connect the computer to network
4. Fetch this script
5. Execute this script

```bash
  $ source setup_ma35d1.sh
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

**If extra features are enabled in image after the done of SDK generation, basically, the script should regenerate the SDK.**
Enabling features in image means changing the **EXTRA_IMAGE_FEATURES**, **IMAGE_INSTALL** in local build configuration file **${YP}/build/conf/local.conf**

# Offline build
Offline build can accelerate the next time image generation, provided that the bitbake completes its image recipe at least one time. However, if server has update the repositories, bitbake can miss the latest patches. In another words, **disabling offline build** lead bitbake to fetch remote repositories.

To force offline build in case of the failure encountered by bitbake's do_fetch task
```
touch ${YP}/build/build.done
source /path/to/setup_ma35d1.sh
```

**${YP}/build/build.done** is a persistent file, indicating that bitbake has downloaded all the source packages the image requires. To download all the packages without actually building image, issue the following command
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
