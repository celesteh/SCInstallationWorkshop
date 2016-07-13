

# SuperCollider on Raspberry Pi

Small, cheap computer is great for installations! 


## Which Pi?

Depending on how much power you need, the Pi 2 or 3 are a safer bet than the 0 or 1.

## Audio quality

The headphone jack on the Pi is not useable and your fancy sound card may or may not work. There are two possible solutions for this: If you only need sound out, the HDMI sound is very high quality. If you need a line in also, get one of those small USB sound cards from adafruit or another Pi-related retailer.

## Preparation

However, the version of SuperCollider that comes with the Pi is old and broken.

There are instructions for compiling it on Raspbian Jessie at: https://supercollider.github.io/development/building-raspberrypi  Note it starts with the -lite version of the raspbian operating system. Scroll down if you've got the normal version.

After you do the `apt-get install`, do one extra command: `sudo apt-get install xvfb`

## Backup your SD cards

If you do a lot of installtion work, you'll need a separate SD card for every installation. But you only need to build SuperCollider once.  Use the same dd command you used to put Raspbian onto the card, but switch the if= and of=. IF is for input file. You want that to be the card now. Of is output file, you want that now to be a **new** file on your hard drive.  Make up a new file name.

When you need a new SD card for another project, write your own image instead of the one you downloaded.

When you're not using the image, it's a good idea to compress it.  Use your compression software of choice. Especially if you're backing it up to dropbox as I've had it corrupt uncompressed img files.

## Headless or no?

If you are not attaching your installation to a monitor, running a GUI is just another thng that can go wrong. `sudo raspi-config` to change the boot options. If your installtion requires a GUI, pick the GUI with automatic login.  If your installtion does not, pick one of the non-GUI items.


## Developing for Pi

It's often much easier to work on your own laptop and SuperCollider is cross platform, so this is an ok strategy. However, you'll need to get the code onto your Pi and keep track of code changes. the easiest way to do with is via git. You can either put your installation code on github (very easy to do, but the whole world can see it) or put a git server on your own laptop.

This way, you can change the code on your laptop, push it to the git server, pull it on the Pi and try it out.  If you make some emergency changes while the istallation is deployed, push it from the pi and pull to your laptop. This way, you stay in sync.


### Modifying your scripts

Depending on your setup, you may need to modify your script, to tell jack what sound card to use to, to set system volume and to patch around a SuperCollider bug

* Is the script running on a pi? Here's an example section of bash:

`#are we on a raspberry pi`

`if \[ -f /etc/rpi-issue \]`

`    then`

`        raspberry=1`

`       # do pi specific stuff`

`    else`

`        raspberry=0`

`fi`

`# . . . Do other things , then, later in the script....`

`# Do something only if we're NOT on a pi`

`if \[ $raspberry -eq 0 \]`

`    then`

`       #...`

`fi`

* Raise amplitude if you're using HDMI

`# Set audio for HDMI`

`amixer cset numid=3 2`

`amixer set PCM 87%`



## Start on boot

Do not use the start on boot instructions in the installation guide, as they don't work in every circumstance!

### GUI

Create a file your\_installtion\_name.desktop . Put in it:

`\[Desktop Entry\]`

`Name=YourInstallationNameNoSpaces`

`Exec=/home/pi/Documents/where/you/put/your/code/installation.sh`

`Type=application`

This will tell the GUI to start your istallation. run the following commands:

`mkdir ~/.config/autostart`

`cp your\_installtion\_name.desktop ~/.config/autostart/`

### Headless

#### Bug fix

There is a bug in version 3.7 of SuperCollider, which means you will need to make a change to the script that starts your installation.

Find the line with `sclang yourInstallation.scd arg1 arg2...`

Replace it with:

`/usr/bin/xvfb-run --server-args="-screen 0, 1280x800x24" /usr/bin/sclang yourInstallation.scd arg1 arg2...`

#### Autostarting


