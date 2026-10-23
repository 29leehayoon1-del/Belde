"""Launch a real Godot bridge for the Node-adapted MV3 worker integration test."""
from pathlib import Path
import importlib.util,subprocess,sys
root=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('bridge_fixture',root/'tests/bridge_godot_test.py')
module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
fixture=module.GodotBridgeTests
fixture.setUpClass()
try:
 result=subprocess.run(['node',str(root/'tests/bridge_worker_test.mjs'),str(fixture.port),fixture.code],timeout=35)
 sys.exit(result.returncode)
finally:fixture.tearDownClass()
