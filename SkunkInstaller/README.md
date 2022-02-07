The <b>SkunkOS Base Installer</b><br>
<br>
<b>Intro:</b> (Instructions follow below)<br>
- Updates/upgrades the FreeBSD base system, and if you choose to let it build a kernel, also sources and ports, and creates boot environments that are helpful in case of later system borking.<br>
- Autoconfigures the system so suspend/resume works out-of-the box. In case your hardware does not support suspend/resume, it will notify you, and explain the technical reason.<br>
- If xorg installation is selected, autodetects and autoconfigures graphics cards and generates a <i>xorg.conf</i> file prepared for multihead operation.<br>
- Then the Base Installer offers to install and configure various popular applications, so no need for manual postconfiguration. Later this will be done by the web-based Base Configurator with its plugins.<br>
- For changing configurations easily after swapping graphics cards, the system can be reconfigured automatically using option -c.<br>
- The window manager I personally use and recommend is FVWM, combined with my experimental Meow+Purr menu browser, which has still some (relatively minor) issues. I designed the configuration so that it is ideal for people who, like me, suffer from ADHD. However, most people will probably rather prefer to install other, more "funky" WMs/DMs. You can switch between those easily, just look at and edit .xinitrc. Currently KDE, and Mate can be installed. Gnome 3 and XFCE is temporarily unavailable, until it reappears in the FreeBSD repositories after they disappeared following the name change of their meta packages on Jan. 31, 2022. Other WMs/DEs will be added later. Please see/use the Discussions page to make suggestions.<br>
<br>
Even if you do not intend to use SkunkOS itself, its Base Installer might be useful for you, as it is probably the fastest and easiest way to slap updates, xorg and the most relevant applications and autoconfigure them ready-to-use onto a freshly installed FreeBSD desktop system.<br>
This can save hours of tedious and error-prone manual work.<br>
<br>
I have tested the SkunkOS Base Installer on a number of different amd64 class computers (bare metal and virtualbox clients) with different graphics cards.<br>
Graphics cards I already verified to work fine are from the nvidia, nv, radeon, mach64, sis, mga and s3 classes. Virtualbox clients' VMSVGA works too, VMware will probably do also.<br>
Other hardware will probably also work out-of-the-box, but some might need updating the installer for handling peculiarities. So confirmations from users are as valuable as problem/issue reports.<br>
<br>
Some tips for reliable suspend/resume functionality on FreeBSD:<br>
- If you use Nvidia graphics cards, configure your computers' BIOS to use legacy/compatible systems mode (CSM) instead of UEFI, if possible. Otherwise suspend/resume cannot work.<br>
- Avoid USB sound dongles. These regularly cause problems. Prefer using onboard sound or sound cards instead.<br>
- If you use HDDs/SSDs on daX (either SAS devices or SATA devices plugged in SCU ports), it is advisable to unmount/remove USB memory sticks before you sleep the computer. These occasionally break the wake-up resume, as the sequence of devices can get reshuffled when the computer resumes, so be careful with this. SATA devices should be plugged into dedicated SATA connectors anyway, because SATA devices have poor performance when connected via SCU ports.<br>
- It is convenient to resume the computer by pressing a keyboard key; this works only on PS/2 type keyboards.
<br>
Again, your feedback is very valuable. Even if it is only confirming that the installer works on particular hardware.<br>
If you encounter any problems, I would appreciate very much if you could create a problem report using the "Issues" button above.<br>
Or go to the "Discussions" button if you like to talk about anything.<br>
<br>
Thank you,<br>
Skunk aka Stefan<br>
<br>
<br>
<b>Instructions:</b><br>
<br>
Install FreeBSD from its installation media.<br>
A standard guided ZFS-on-root installation, basically always pressing enter, except when entering the root password and choosing the drive to install, is completely sufficient.<br>
Setting up an user during the FreeBSD installation is not necessary.<br>
It is easier to do this in the SkunkOS Base Installer.<br>

After you rebooted that newly-made FreeBSD installation, log in as root and enter this command:<br>
<br>
&nbsp;&nbsp;&nbsp;&nbsp; <b>fetch https://raw.githubusercontent.com/SkunkOS/SkunkInstaller/main/skunkinstall.sh -o - | sh</b><br>
<br>
(If you don't like piping an external script into your shell, just do manually what the script does.)<br>

When the installation starts, just follow the instructions in the dialog boxes.<br>
After the system has been updated it will tell you to reboot. After the reboot log in as "root" and restart the install script with the command "<b>/root/bootie -i</b>".<br>
The installation will then continue where it left off.<br>.
<br>
When it finishes, your now-ready-to-use system can start up X Window directly, without need to reboot.<br>
<br>
If you opt to only install the console part of SkunkOS, and later decide to install its X Window part also, use the command "<b>/root/bootie.pl -i -x</b>".<br>
You also can boot into the boot environments created by the installer to restore the system. When you rerun the installer, it will detect this and offer you according options.<br>
