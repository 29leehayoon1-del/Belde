"""Chromium -> MV3 service worker -> C native host -> real Godot bridge.

Uses an isolated browser profile/XDG configuration; never installs in the user's browser.
"""
from __future__ import annotations
import importlib.util,json,os,pathlib,tempfile,time
from playwright.sync_api import sync_playwright

ROOT=pathlib.Path(__file__).resolve().parents[1]

def main():
    extension_id=(ROOT/'extension/EXTENSION-ID.txt').read_text().strip()
    # Respect managed browser policy. A skipped install is not a successful run.
    for policy_dir in [pathlib.Path('/etc/chromium/policies/managed'),pathlib.Path('/etc/opt/chrome/policies/managed')]:
        if not policy_dir.exists():continue
        for policy_file in policy_dir.glob('*.json'):
            try:policy=json.loads(policy_file.read_text())
            except (OSError,ValueError):continue
            blocked=policy.get('ExtensionInstallBlocklist',[])
            allowed=policy.get('ExtensionInstallAllowlist',[])
            if ('*' in blocked or extension_id in blocked) and extension_id not in allowed:
                print('SKIPPED: managed Chromium policy blocks installing the Belde extension. No browser policy was changed.')
                return 77
    spec=importlib.util.spec_from_file_location('belde_bridge_fixture',ROOT/'tests/bridge_godot_test.py')
    module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
    fixture=module.GodotBridgeTests
    fixture.setUpClass()
    with tempfile.TemporaryDirectory(prefix='belde-chrome-') as tmp:
        directory=pathlib.Path(tmp);config=directory/'config'
        extension_id=(ROOT/'extension/EXTENSION-ID.txt').read_text().strip()
        manifest={'name':'com.belde.editor','description':'Belde integration test host','path':str(ROOT/'native/bin/belde_host'),'type':'stdio','allowed_origins':[f'chrome-extension://{extension_id}/']}
        for browser in ['chromium','google-chrome','google-chrome-for-testing']:
            path=config/browser/'NativeMessagingHosts';path.mkdir(parents=True)
            (path/'com.belde.editor.json').write_text(json.dumps(manifest))
        env=os.environ.copy();env.update({'XDG_CONFIG_HOME':str(config),'XDG_DATA_HOME':str(directory/'data'),'XDG_CACHE_HOME':str(directory/'cache'),'BELDE_BRIDGE_PORT':str(fixture.port)})
        try:
            with sync_playwright() as p:
                context=p.chromium.launch_persistent_context(str(directory/'profile'),executable_path='/usr/bin/chromium',headless=os.environ.get('BELDE_HEADLESS_TEST','1')!='0',env=env,ignore_default_args=['--disable-extensions'],args=['--no-sandbox','--disable-dev-shm-usage',f'--disable-extensions-except={ROOT/"extension"}',f'--load-extension={ROOT/"extension"}'])
                workers=context.service_workers
                if not workers:
                    try:context.wait_for_event('serviceworker',timeout=10000)
                    except Exception:pass
                print('Extension workers:',[worker.url for worker in context.service_workers])
                errors=[]
                page=context.new_page();page.on('pageerror',lambda error:errors.append(str(error)))
                page.goto(f'chrome-extension://{extension_id}/popup.html')
                page.locator('#code').fill(fixture.code);page.locator('#connect').click()
                try:page.wait_for_function('document.getElementById("status").textContent === "Synced"',timeout=15000)
                except Exception:
                    print('Popup status:',page.locator('#status').inner_text());print('Popup message:',page.locator('#message').inner_text());raise
                assert page.locator('#connected-panel').is_visible()
                assert page.locator('#act').inner_text()=='1'
                editor=context.new_page();editor.on('pageerror',lambda error:errors.append(str(error)))
                editor.goto(f'chrome-extension://{extension_id}/editor.html')
                editor.wait_for_function('document.getElementById("pair-overlay").hidden',timeout=10000)
                assert editor.locator('#status').inner_text()=='Synced'
                # Select tower, place it on an empty tile, verify PC-authoritative revision.
                editor.locator('[data-tool=tower]').click()
                before=editor.locator('#revision').inner_text()
                canvas=editor.locator('#map');rect=canvas.bounding_box()
                ratio=1024/640;width=rect['width'];height=rect['height'];left=rect['x'];top=rect['y']
                if width/height>ratio:
                    actual=height*ratio;left+=(width-actual)/2;width=actual
                else:
                    actual=width/ratio;top+=(height-actual)/2;height=actual
                editor.mouse.click(left+width*(4.5/32),top+height*(6.5/20))
                editor.wait_for_function('document.getElementById("history").children.length === 1',timeout=10000)
                editor.wait_for_function('(before)=>document.getElementById("revision").textContent!==before',arg=before,timeout=10000)
                assert 'Build Palisade Roost' in editor.locator('#history').inner_text()
                # Popup and detached views share one connection, not competing editor leases.
                assert page.locator('#status').inner_text()=='Synced'
                editor.locator('#disconnect').click()
                page.wait_for_function('!document.getElementById("connected-panel").hidden===false',timeout=5000)
                assert page.locator('#pair-panel').is_visible()
                assert not errors,errors
                context.close()
            print('PASS: actual Chromium MV3 pairing, shared views, tower edit/revision, and disconnect via native C host + Godot bridge.')
        finally:fixture.tearDownClass()

if __name__=='__main__':raise SystemExit(main())
