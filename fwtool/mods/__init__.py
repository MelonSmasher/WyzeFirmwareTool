import shutil
import re


def enable_usbnet(module_dir):
    print('')
    print('######################################')
    print('Enabling USB ethernet support')
    print('######################################')
    print('Enabling USB ethernet support for ASIX based ethernet adapters...')
    print('Copying kernel modules', end='... ')
    shutil.copyfile('support/ko/usbnet.ko', module_dir)
    shutil.copyfile('support/ko/asix.ko', module_dir)
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
