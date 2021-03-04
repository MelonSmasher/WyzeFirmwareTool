import shutil
import re
import os
import subprocess
import pathlib
import crypt
import getpass


def __copy_mod_script(squashfs_1, script_name, script_path):
    hook_file = os.path.join(squashfs_1, 'root', 'mods', script_name)
    shutil.copyfile(script_path, hook_file)
    subprocess.run(['sudo', 'chmod', '+x', hook_file])
    subprocess.run(['sudo', 'chown', '501:0', hook_file])


def __copy_modded_system_bin(jffs2, script_name):
    src_file = os.path.join('support', 'mods', 'scripts', script_name)
    dest_file = os.path.join(jffs2, 'bin', script_name)
    shutil.copyfile(src_file, dest_file)
    subprocess.run(['sudo', 'chmod', '+x', dest_file])
    subprocess.run(['sudo', 'chown', '501:0', dest_file])


def __update_hook(squashfs_1, current, new):
    print('Updating mod hook', end='... ')
    hook_script = os.path.join(squashfs_1, 'root', 'mods', 'mod_hooks.sh')
    with open(hook_script, 'r+') as f:
        text = f.read()
        text = re.sub(
            current,
            new,
            text
        )
        f.seek(0)
        f.write(text)
        f.truncate()
    print('Done!')


def enable_mods(squashfs_1, jffs2):
    print('')
    print('######################################')
    print('Enabling mod support')
    print('######################################')
    print('Copying mod hook script', end='... ')
    mod_dir = os.path.join(squashfs_1, 'root', 'mods')
    pathlib.Path(mod_dir).mkdir(parents=True, exist_ok=True)
    subprocess.run(['sudo', 'chown', '501:0', mod_dir])
    __copy_mod_script(squashfs_1, 'mod_hooks.sh', 'support/mods/scripts/mod_hooks.sh')
    print('Done!')
    print('Updating init files', end='... ')
    init_file = os.path.join(squashfs_1, 'etc', 'init.d', 'rcS')
    with open(init_file, 'a') as f:
        f.write('\n# Inject the mod hook script\n/root/mods/mod_hooks.sh &')
    print('Done!')


def disable_wlan(squashfs_1, jffs2):
    print('')
    print('######################################')
    print('Disabling wireless connection support')
    print('######################################')
    print('Copying wlan0_kill script', end='... ')
    __copy_mod_script(squashfs_1, 'wlan0_kill.sh', 'support/mods/scripts/wlan0_kill.sh')
    print('Done!')
    print('Replacing wpa_cli', end='... ')
    __copy_modded_system_bin(jffs2, 'wpa_cli')
    print('Done!')
    print('Replacing wpa_supplicant', end='... ')
    __copy_modded_system_bin(jffs2, 'wpa_supplicant')
    print('Done!')
    print('Replacing restart_wlan0.sh', end='... ')
    __copy_modded_system_bin(jffs2, 'restart_wlan0.sh')
    print('Done!')
    __update_hook(squashfs_1, '# /root/mods/wlan0_kill.sh &', '/root/mods/wlan0_kill.sh &')


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
    print('Copying eth0_init script', end='... ')
    __copy_mod_script(squashfs_1, 'eth0_init.sh', 'support/mods/scripts/eth0_init.sh')
    print('Done!')
    __update_hook(squashfs_1, '# /root/mods/eth0_init.sh &', '/root/mods/eth0_init.sh &')


def enable_telnet(squashfs_1):
    print('')
    print('######################################')
    print('Enabling telnet')
    print('######################################')
    print('Enabling persistent telnet server...')
    print('Changing root password...')
    pwd = getpass.getpass()
    pwd_confirm = getpass.getpass('Retype password: ')
    while pwd != pwd_confirm:
        print('Passwords do not match. Try again')
        pwd = getpass.getpass()
        pwd_confirm = getpass.getpass('Retype password: ')
    hash_string = 'root:' + crypt.crypt(pwd, crypt.mksalt(crypt.METHOD_MD5)) + ':10933:0:99999:7:::'
    shadow_path = os.path.join(squashfs_1, 'etc', 'shadow')
    with open(shadow_path, 'w') as shadow_file:
        shadow_file.write(hash_string)
    print('Done!')
    print('Updating init rcS', end='... ')
    rcS_file = os.path.join(squashfs_1, 'etc', 'init.d', 'rcS')
    with open(rcS_file, 'r+') as f:
        text = f.read()
        text = re.sub('telnetd &', 'busybox telnetd &', text)
        f.seek(0)
        f.write(text)
        f.truncate()
    print('Done!')
