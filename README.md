# ma35d1-build-environment
 an unattended bash script to setup build  environment in native Linux without docker inside for ma35d1

# Host OS
Ubuntu Desktop 20.04 LTS 64-bit

# Installing
1. Before installing Ubuntu Desktop 20.04 LTS 64-bit, disconnect the computer from network
2. Install Ubuntu Desktop 20.04
3. Connect the computer to network
4. Fetch this script
5. Execute this script
  * $ chmod +x setup_ma35d1.sh
  * $ source setup_ma35d1.sh

# Selecting board
The MA35D1 yocto project supports three boards: **IoT**, **EVB**, and **SOM**.

When the script prompts to select board, just type **'i' for IoT, 'e' for EVB, or 's' for SOM**. By default, if user does not choose the board, EVB board will be selected. 

<table>
  <thead>
    <tr>
      <th>BOARD</th>
      <th>DISTRO</th>
      <th>MACHINE</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>EVB</td>
      <td>nvt-ma35d1-directfb</td>
      <td>ma35d1-evb</td>
    </tr>
   
   <tr>
      <td>IOT</td>
      <td>nvt-ma35d1</td>
      <td>ma35d1-iot</td>
    </tr>
   
   <tr>
      <td>SOM</td>
      <td>nvt-ma35d1</td>
      <td>ma35d1-som</td>
    </tr>
  
  </tbody>
</table>




# Building issues
Usually, due to unstable network connection, this script often is executed unsuccessfully. Reexcuting this script again and again can make the build passed, but that is not recommended.

If the script has synchronized the repository (repo sync --force-sync) without problem, open another terminal (press Ctrl + Alt + T or Ctrl + Shift + I) and follow the below steps to make the build passed.

1. $ cd ~/Project/yocto
2. DISTRO=nvt-ma35d1-directfb MACHINE=ma35d1-evb source sources/init-build-env build
3. bitbake nvt-image-qt5

Do 'bitbake nvt-image-qt5' again and again until the final image is generated out! Note that this script uses shell command 'until bitbake nvt-image-qt5' to ensure the image is built out.
