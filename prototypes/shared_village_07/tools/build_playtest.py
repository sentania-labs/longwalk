"""Build the private prototype locally, retaining a reusable, verified art pack."""
from pathlib import Path
import argparse
import hashlib
import json
import shutil
import subprocess
import zipfile
import os
import tempfile

ROOT = Path(__file__).resolve().parents[1]
ENGINE = ROOT.parents[1] / 'tools/godot/godot'
BUILD = ROOT / 'build'
ARTIFACTS = ROOT / 'artifacts'


def digest(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def run(args, name, timeout=180):
    log = BUILD / (name + '.log')
    with log.open('w') as output:
        with tempfile.TemporaryDirectory(prefix='longwalk-test-') as test_data:
            result = subprocess.run([str(arg) for arg in args], cwd=ROOT, stdout=output,
                                    stderr=subprocess.STDOUT, timeout=timeout,
                                    env={**os.environ, 'LONGWALK_TEST_DATA': test_data})
    text = log.read_text()
    if result.returncode or 'SCRIPT ERROR:' in text or '\nERROR:' in text:
        raise RuntimeError(f'{name} failed; inspect {log}')
    print(name + ' passed', flush=True)


def archive(target, files):
    with zipfile.ZipFile(target, 'w', zipfile.ZIP_DEFLATED, compresslevel=6) as result:
        for source, name in files:
            result.write(source, name)


def main():
    options = argparse.ArgumentParser()
    options.add_argument('--version', default='development')
    options.add_argument('--export-only', action='store_true', help='Leave Windows binaries unpackaged for CI signing')
    options.add_argument('--package-only', action='store_true', help='Package already exported and signed Windows binaries')
    options.add_argument('--server', action='store_true', help='Also build and bundle the Docker world')
    args = options.parse_args()
    BUILD.mkdir(exist_ok=True)
    ARTIFACTS.mkdir(exist_ok=True)
    (BUILD / '.gdignore').touch()
    (ARTIFACTS / '.gdignore').touch()
    if args.package_only:
        package(args.version)
        return
    for platform in ['linux', 'windows']:
        (BUILD / platform).mkdir(exist_ok=True)
    run([ENGINE, '--headless', '--path', ROOT, '--editor', '--import'], 'import')
    for test in ['workshop', 'skills', 'community', 'day_cycle', 'lantern_moths', 'character_name', 'context_picking', 'snapshot_packets', 'storage', 'workshop_storage', 'recovery_disconnect', 'move_queue', 'simulation_clock', 'travel', 'avoidance', 'admin_rules']:
        run([ENGINE, '--headless', '--path', ROOT, '--script', f'res://test/{test}.gd'], 'test-' + test, 45)
    art_inputs = sorted(p for p in (ROOT / 'assets').iterdir() if p.is_file())
    art_fingerprint = hashlib.sha256(''.join(p.name + digest(p) for p in art_inputs).encode()).hexdigest()
    art = BUILD / 'Longwalk-Art-01.pck'
    fingerprint_file = BUILD / 'art-inputs.sha256'
    if not art.exists() or not fingerprint_file.exists() or fingerprint_file.read_text() != art_fingerprint:
        run([ENGINE, '--headless', '--path', ROOT, '--export-pack', 'World Art', art], 'art-pack')
        fingerprint_file.write_text(art_fingerprint)
    runtime = sorted(list(ROOT.glob('*.gd')) + list(ROOT.glob('*.gdshader')) + list(ROOT.glob('*.tscn')) + [ROOT / 'project.godot'] + list((ROOT / 'src').rglob('*.gd')) + list((ROOT / 'world').glob('*.json')) + list((ROOT / 'ui').rglob('*.svg')) + list((ROOT / 'art').glob('*.svg')) + list((ROOT / 'web').glob('*')))
    build_id = hashlib.sha256(''.join(str(p.relative_to(ROOT)) + digest(p) for p in runtime).encode() + digest(art).encode()).hexdigest()
    manifest = {'client': 'Admin 07', 'protocol': 'shared-village-07', 'build_id': build_id, 'version': args.version,
                'art_file': art.name, 'art_sha256': digest(art), 'art_bytes': art.stat().st_size,
                'baseline_sha256': digest(ROOT / 'world/baseline.json')}
    (ROOT / 'release_manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    for platform, preset, name in [('linux', 'Linux Rivers', 'Longwalk-Shared-Village-07.x86_64'),
                                   ('windows', 'Windows Rivers', 'Longwalk-Shared-Village-07.exe')]:
        run([ENGINE, '--headless', '--path', ROOT, '--export-release', preset, BUILD / platform / name], 'export-' + platform)
        shutil.copy2(art, BUILD / platform / art.name)
    if not args.export_only:
        package(args.version)
    if args.server:
        run(['python3', ROOT / 'server/prepare_context.py'], 'server-context')
        run(['docker', 'build', '-t', 'longwalk-shared-village:07', BUILD / 'server-context'], 'server-image', 300)


def package(version):
    art = BUILD / 'Longwalk-Art-01.pck'
    manifest = json.loads((ROOT / 'release_manifest.json').read_text())
    if manifest.get('version') != version:
        raise RuntimeError('Requested version does not match exported manifest')
    start = ARTIFACTS / 'START-HERE.txt'
    start.write_text(f"LONGWALK ADMIN 07 ({version})\n\nExtract the full ZIP and keep the EXE and Longwalk-Art-01.pck together.\nLaunch and choose Connection settings. Use your deployed server address and\nUDP port (default 7777). Use this client with a matching Admin 07 server.\nAdministration uses the separate web console, TCP 8888 behind your HTTPS proxy.\nWindows binaries in tagged CI releases are signed before packaging.\n")
    common = [(start, start.name), (ROOT / 'release_manifest.json', 'release_manifest.json')]
    windows = BUILD / 'windows/Longwalk-Shared-Village-07.exe'
    archive(ARTIFACTS / 'Longwalk-Shared-Village-07-Windows.zip', [(windows, windows.name), (art, art.name)] + common)
    archive(ARTIFACTS / 'Longwalk-Shared-Village-07-Client-Update.zip', [(windows, windows.name)] + common)
    linux = BUILD / 'linux/Longwalk-Shared-Village-07.x86_64'
    archive(ARTIFACTS / 'Longwalk-Shared-Village-07-Linux.zip', [(linux, linux.name), (art, art.name)] + common)
    manifest['windows_exe_sha256'] = digest(windows)
    manifest['linux_exe_sha256'] = digest(BUILD / 'linux/Longwalk-Shared-Village-07.x86_64')
    (ARTIFACTS / 'BUILD-MANIFEST.json').write_text(json.dumps(manifest, indent=2) + '\n')
    packages = sorted(p for p in ARTIFACTS.iterdir() if p.suffix in ['.zip', '.tar'])
    (ARTIFACTS / 'SHA256SUMS.txt').write_text(''.join(digest(p) + '  ' + p.name + '\n' for p in packages))
    print('Built artifacts in ' + str(ARTIFACTS), flush=True)


if __name__ == '__main__':
    main()
