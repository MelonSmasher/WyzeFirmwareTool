import shutil
import re
import os


def enable_usbnet(squashfs_1, squashfs_2, jffs2):
    print('')
    print('######################################')
    print('Enabling USB ethernet support')
    print('######################################')
    print('Enabling USB ethernet support for ASIX based ethernet adapters...')
    print('Copying kernel modules', end='... ')
    shutil.copyfile('support/mods/ko/usbnet.ko', os.path.join(squashfs_2, 'usbnet.ko'))
    shutil.copyfile('support/mods/ko/asix.ko', os.path.join(squashfs_2, 'asix.ko'))
    print('Done!')
    print('Copying custom script', end='... ')
    shutil.copyfile('support/mods/scripts/eth0_init.sh', os.path.join(squashfs_1, 'root', 'eth0_init.sh'))
    print('Done!')
    print('Updating init file', end='... ')
    init_file = os.path.join(squashfs_1, 'etc', 'init.d', 'rcS')
    file_object = open(init_file, 'a')
    file_object.write('chmod a+x /root/eth0_init.sh')
    file_object.write('/root/eth0_init.sh &')
    print('Done!')


def enable_telnet(rcS_file):
    print('')
    print('######################################')
    print('Enabling telnet')
    print('######################################')
    print('Enabling persistent telnet server...')
    print('Updating init rcS', end='... ')
    with open(rcS_file, 'r+') as f:
        text = f.read()
        text = re.sub('telnetd &', 'busybox telnetd &', text)
        f.seek(0)
        f.write(text)
        f.truncate()
    print('Done!')
