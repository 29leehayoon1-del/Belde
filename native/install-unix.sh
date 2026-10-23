#!/bin/sh
# Register only this user's Chrome/Chromium native host; no root access required.
set -eu
if [ "$#" -gt 1 ]; then
    printf 'Usage: %s EXTENSION_ID\n' "$0" >&2
    exit 2
fi
BELDE_EXTENSION_ID=${1:-ngolglhaedkpheljgabbfafifbimmlle}
case "$BELDE_EXTENSION_ID" in
    *[!a-p]*|'') printf 'Extension ID must contain exactly 32 lowercase letters a-p.\n' >&2; exit 2 ;;
esac
if [ "${#BELDE_EXTENSION_ID}" -ne 32 ]; then
    printf 'Extension ID must contain exactly 32 lowercase letters a-p.\n' >&2
    exit 2
fi
BELDE_SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
command -v python3 >/dev/null 2>&1 || { printf 'Python 3 is needed by this one-time manifest installer.\n' >&2; exit 1; }
python3 - "$BELDE_EXTENSION_ID" "$BELDE_SCRIPT_DIR" <<'PY'
import json, os, pathlib, platform, shlex, shutil, sys
extension_id, source_directory = sys.argv[1:]
source_directory = pathlib.Path(source_directory)
base = pathlib.Path.home()
if platform.system() == 'Darwin':
    install = base / 'Library/Application Support/Belde/NativeMessaging'
    browsers = [base / 'Library/Application Support/Google/Chrome/NativeMessagingHosts',
                base / 'Library/Application Support/Chromium/NativeMessagingHosts']
else:
    install = pathlib.Path(os.environ.get('XDG_DATA_HOME', base / '.local/share')) / 'belde/native-messaging'
    config = pathlib.Path(os.environ.get('XDG_CONFIG_HOME', base / '.config'))
    browsers = [config / 'google-chrome/NativeMessagingHosts', config / 'chromium/NativeMessagingHosts']
install.mkdir(parents=True, exist_ok=True)
host = install / 'belde_host'
source = source_directory / 'bin/belde_host'
magic = source.read_bytes()[:4] if source.is_file() else b''
is_native = ((platform.system() == 'Darwin' and magic in [b'\xcf\xfa\xed\xfe', b'\xca\xfe\xba\xbe', b'\xfe\xed\xfa\xcf'])
             or (platform.system() == 'Linux' and magic == b'\x7fELF'))
if is_native:
    shutil.copy2(source, host)
else:
    fallback = source_directory / 'belde_host.py'
    if not fallback.is_file(): raise SystemExit('No native binary or Python fallback exists in this package.')
    target = install / 'belde_host.py'
    shutil.copy2(fallback, target)
    target.chmod(0o600)
    host.write_text('#!/bin/sh\nexec ' + shlex.quote(sys.executable) + ' ' + shlex.quote(str(target.resolve())) + ' "$@"\n')
host.chmod(0o700)
manifest = {'name':'com.belde.editor','description':'Belde connected map editor',
            'path':str(host.resolve()),'type':'stdio',
            'allowed_origins':['chrome-extension://' + extension_id + '/']}
for folder in browsers:
    folder.mkdir(parents=True, exist_ok=True)
    path = folder / 'com.belde.editor.json'
    path.write_text(json.dumps(manifest, indent=2) + '\n')
    path.chmod(0o600)
print('Belde native messaging host installed for this user.')
print('Start Belde and enter its pairing code in the extension.')
PY
