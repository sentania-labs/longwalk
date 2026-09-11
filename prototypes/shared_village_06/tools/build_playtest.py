"""Build the private prototype locally, retaining a reusable, verified art pack."""
from pathlib import Path
import argparse
import hashlib
import json
import shutil
import subprocess
import zipfile

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
        result = subprocess.run([str(arg) for arg in args], cwd=ROOT, stdout=output,
                                stderr=subprocess.STDOUT, timeout=timeout)
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
    options.add_argument('--server', action='store_true', help='Also build and bundle the Docker world')
    args = options.parse_args()
    BUILD.mkdir(exist_ok=True)
    ARTIFACTS.mkdir(exist_ok=True)
    (BUILD / '.gdignore').touch()
    (ARTIFACTS / '.gdignore').touch()
    for platform in ['linux', 'windows']:
        (BUILD / platform).mkdir(exist_ok=True)
    run([ENGINE, '--headless', '--path', ROOT, '--editor', '--import'], 'import')
    for test in ['workshop', 'skills', 'community', 'day_cycle', 'lantern_moths', 'character_name', 'context_picking', 'snapshot_packets', 'storage', 'workshop_storage', 'recovery_disconnect', 'move_queue', 'simulation_clock', 'travel', 'avoidance']:
        run([ENGINE, '--headless', '--path', ROOT, '--script', f'res://test/{test}.gd'], 'test-' + test, 45)
    art_inputs = sorted(p for p in (ROOT / 'assets').iterdir() if p.is_file())
    art_fingerprint = hashlib.sha256(''.join(p.name + digest(p) for p in art_inputs).encode()).hexdigest()
    art = BUILD / 'Longwalk-Art-01.pck'
    fingerprint_file = BUILD / 'art-inputs.sha256'
    if not art.exists() or not fingerprint_file.exists() or fingerprint_file.read_text() != art_fingerprint:
        run([ENGINE, '--headless', '--path', ROOT, '--export-pack', 'World Art', art], 'art-pack')
        fingerprint_file.write_text(art_fingerprint)
    runtime = sorted(list(ROOT.glob('*.gd')) + list(ROOT.glob('*.gdshader')) + list(ROOT.glob('*.tscn')) + [ROOT / 'project.godot'] + list((ROOT / 'src').rglob('*.gd')) + list((ROOT / 'world').glob('*.json')) + list((ROOT / 'ui').rglob('*.svg')) + list((ROOT / 'art').glob('*.svg')))
    build_id = hashlib.sha256(''.join(str(p.relative_to(ROOT)) + digest(p) for p in runtime).encode() + digest(art).encode()).hexdigest()
    manifest = {'client': 'Working Day 06', 'protocol': 'shared-village-06', 'build_id': build_id,
                'art_file': art.name, 'art_sha256': digest(art), 'art_bytes': art.stat().st_size,
                'baseline_sha256': digest(ROOT / 'world/baseline.json')}
    (ROOT / 'release_manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    for platform, preset, name in [('linux', 'Linux Rivers', 'Longwalk-Shared-Village-06.x86_64'),
                                   ('windows', 'Windows Rivers', 'Longwalk-Shared-Village-06.exe')]:
        run([ENGINE, '--headless', '--path', ROOT, '--export-release', preset, BUILD / platform / name], 'export-' + platform)
        shutil.copy2(art, BUILD / platform / art.name)
    start = ARTIFACTS / 'START-HERE.txt'
    start.write_text("""LONGWALK WORKING DAY 06\n\nExtract the complete ZIP. Keep the EXE and Longwalk-Art-01.pck together.\nLaunch the EXE and choose Connection settings. For Scott's parallel sprint\nplaytest, use 172.16.3.13, UDP 7778, and your existing traveler profile.\nThe original 05 world remains on UDP 7777 and needs client 05.\nStandard new server installs use UDP 7777. Open Journal for the work loop.\n\nWindows needs playtesting; packaged Linux and server checks are recorded.\nFor later client-only updates, retain the matching art pack beside the EXE.\nA missing or mismatched pack opens a recovery screen with a file chooser.\n""")
    common = [(start, start.name), (ROOT / 'release_manifest.json', 'release_manifest.json')]
    windows = BUILD / 'windows/Longwalk-Shared-Village-06.exe'
    archive(ARTIFACTS / 'Longwalk-Shared-Village-06-Windows.zip', [(windows, windows.name), (art, art.name)] + common)
    archive(ARTIFACTS / 'Longwalk-Shared-Village-06-Client-Update.zip', [(windows, windows.name)] + common)
    manifest['windows_exe_sha256'] = digest(windows)
    manifest['linux_exe_sha256'] = digest(BUILD / 'linux/Longwalk-Shared-Village-06.x86_64')
    if args.server:
        run(['python3', ROOT / 'server/prepare_context.py'], 'server-context')
        run(['docker', 'build', '-t', 'longwalk-shared-village:06', BUILD / 'server-context'], 'server-image', 300)
        manifest['image'] = subprocess.check_output(['docker', 'image', 'inspect', '--format', '{{.Id}}', 'longwalk-shared-village:06'], text=True).strip()
        tar = ARTIFACTS / 'longwalk-shared-village-06.tar'
        run(['docker', 'save', '-o', tar, 'longwalk-shared-village:06'], 'server-tar')
        manifest['server_tar_sha256'] = digest(tar)
    (ARTIFACTS / 'BUILD-MANIFEST.json').write_text(json.dumps(manifest, indent=2) + '\n')
    if args.server:
        run(['python3', ROOT / 'tools/package_server.py'], 'server-package')
    packages = sorted(p for p in ARTIFACTS.iterdir() if p.suffix in ['.zip', '.tar'])
    (ARTIFACTS / 'SHA256SUMS.txt').write_text(''.join(digest(p) + '  ' + p.name + '\n' for p in packages))
    print('Built artifacts in ' + str(ARTIFACTS), flush=True)


if __name__ == '__main__':
    main()
