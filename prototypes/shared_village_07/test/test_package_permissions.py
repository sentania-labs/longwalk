"""The Linux download must remain executable when assembled by a Windows host."""
import importlib.util
from pathlib import Path
import stat
import subprocess
import tempfile
import zipfile

source = Path(__file__).resolve().parents[1] / 'tools/build_playtest.py'
spec = importlib.util.spec_from_file_location('build_playtest', source)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
with tempfile.TemporaryDirectory(prefix='longwalk-package-') as scratch:
    root = Path(scratch)
    module.ROOT = root
    module.BUILD = root/'build'
    module.ARTIFACTS = root/'artifacts'
    (module.BUILD/'linux').mkdir(parents=True)
    (module.BUILD/'windows').mkdir()
    module.ARTIFACTS.mkdir()
    name = 'Longwalk-Shared-Village-07.x86_64'
    linux = module.BUILD/'linux'/name
    linux.write_text('#!/bin/sh\necho LINUX_PACKAGE_RUNS\n')
    linux.chmod(0o644)  # Model extraction onto a filesystem without Unix exec bits.
    (module.BUILD/'windows'/'Longwalk-Shared-Village-07.exe').write_bytes(b'fixture')
    (module.BUILD/'Longwalk-Art-01.pck').write_bytes(b'art fixture')
    (root/'release_manifest.json').write_text('{"version":"fixture"}')
    module.package('fixture')
    package = module.ARTIFACTS/'Longwalk-Shared-Village-07-Linux.zip'
    with zipfile.ZipFile(package) as archive:
        entry = archive.getinfo(name)
        assert entry.create_system == 3 and stat.S_IMODE(entry.external_attr >> 16) == 0o755, 'Linux ZIP lost executable permission'
    subprocess.run(['unzip','-q',str(package),'-d',str(root/'extracted')],check=True)
    assert subprocess.check_output([str(root/'extracted'/name)],text=True).strip() == 'LINUX_PACKAGE_RUNS'
print('PACKAGE PERMISSIONS PASSED: Linux client runs after extraction from non-executable source')
