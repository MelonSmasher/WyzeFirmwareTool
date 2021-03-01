import shutil
import re
import os
import subprocess


def enable_usbnet(squashfs_2, jffs2):
    print('')
    print('######################################')
    print('Enabling USB ethernet support')
    print('######################################')
    print('Enabling USB ethernet support for ASIX based ethernet adapters...')
    print('Copying kernel modules', end='... ')
    shutil.copyfile('support/ko/usbnet.ko', os.path.join(squashfs_2, 'usbnet.ko'))
    shutil.copyfile('support/ko/asix.ko', os.path.join(squashfs_2, 'asix.ko'))
    print('Done!')
    print('Updating init files', end='... ')
    init_files = [
        os.path.join(jffs2, 'init', 'app_init.sh'),
        os.path.join(jffs2, 'init', 'app_init_xiao.sh'),
        os.path.join(jffs2, 'init', 'app_init_da.sh')
    ]

    for init_file in init_files:
        with open(init_file, 'r+') as f:
            text = f.read()
            text = re.sub(
                "insmod /driver/rtl8189ftv\\.ko",
                "insmod /driver/rtl8189ftv.ko\ninsmod /driver/usbnet.ko\ninsmod /driver/asix.ko\n",
                text
            )
            f.seek(0)
            f.write(text)
            f.truncate()
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
