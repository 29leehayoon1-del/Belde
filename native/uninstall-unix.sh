#!/bin/sh
set -eu
command -v python3 >/dev/null 2>&1 || { printf 'Python 3 is needed by this one-time uninstaller.\n' >&2; exit 1; }
python3 - <<'PY'
import os, pathlib, platform, shutil
base = pathlib.Path.home()
if platform.system() == 'Darwin':
    install = base / 'Library/Application Support/Belde/NativeMessaging'
    browsers = [base / 'Library/Application Support/Google/Chrome/NativeMessagingHosts',base / 'Library/Application Support/Chromium/NativeMessagingHosts']
else:
    install = pathlib.Path(os.environ.get('XDG_DATA_HOME', base / '.local/share')) / 'belde/native-messaging'
    config = pathlib.Path(os.environ.get('XDG_CONFIG_HOME', base / '.config'))
    browsers = [config / 'google-chrome/NativeMessagingHosts',config / 'chromium/NativeMessagingHosts']
for folder in browsers:
    path = folder / 'com.belde.editor.json'
    if path.exists(): path.unlink()
if install.exists(): shutil.rmtree(install)
print('Belde native host removed for this user. Game saves were kept.')
PY
