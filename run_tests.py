"""Run the actual Luau simulation with a CLI Vector3 adapter; no third-party Python packages."""
import argparse
from pathlib import Path
import shutil
import subprocess

parser = argparse.ArgumentParser()
parser.add_argument('--luau', default='luau', help='Path to the official Luau CLI executable')
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
exe = shutil.which(args.luau)
if not exe:
    parser.error('Luau CLI not found; download it from github.com/luau-lang/luau/releases')

def wrap(name, path, replacements=()):
    source = (root/path).read_text(encoding='utf-8')
    for old, new in replacements:
        if old not in source:
            raise RuntimeError('Module dependency changed: '+old)
        source = source.replace(old, new, 1)
    return f'local {name}=(function()\n{source}\nend)()\n'

code = wrap('Vector3', 'tests/vector3.luau')
code += wrap('Config', 'src/AfterechoSourceConfig.luau')
code += wrap('Movement', 'src/AfterechoSourceMovement.luau', [
    ('local C = require(script.Parent.AfterechoSourceConfig)', 'local C = Config')])
code += wrap('runTests', 'tests/AfterechoMovementTests.luau')
code += '''
local report=runTests(Movement)
for _,check in ipairs(report.checks) do
 print((check.passed and "PASS " or "FAIL ")..check.name, type(check.value)=='table' and '' or tostring(check.value))
end
print(string.format("RESULT %d passed; %d failed",report.passed,report.failed))
assert(report.failed==0,"Movement regression checks failed")
'''
cache=root/'.test-cache'
cache.mkdir(exist_ok=True)
entry=cache/'runner.luau'
entry.write_text(code,encoding='utf-8')
result=subprocess.run([exe,str(entry)],cwd=root,check=False)
raise SystemExit(result.returncode)
