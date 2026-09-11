"""Rebundle deployment docs and evidence without rebuilding a tested image."""
from pathlib import Path
import hashlib
import json
import zipfile

ROOT = Path(__file__).resolve().parents[1]
ARTIFACTS = ROOT / 'artifacts'


def digest(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def main():
    manifest = ARTIFACTS / 'BUILD-MANIFEST.json'
    metadata = json.loads(manifest.read_text())
    tar = ARTIFACTS / 'longwalk-shared-village-06.tar'
    if digest(tar) != metadata['server_tar_sha256']:
        raise RuntimeError('Server image archive differs from the tested build manifest')
    files = [(tar, tar.name), (ROOT / 'README.md', 'README.md'), (ROOT / 'FOLLOW-UPS.md', 'FOLLOW-UPS.md'), (ROOT / 'AUTHORIZATION.md', 'AUTHORIZATION.md'), (manifest, manifest.name)]
    files += [(ROOT / 'server' / name, name) for name in ['compose.yaml', 'compose.playtest.yaml', 'kubernetes.yaml', 'START-SERVER.txt']]
    files += [(ROOT / 'test/kind' / name, 'test/kind/' + name) for name in ['cluster.yaml', 'service.yaml']]
    files += [(p, 'evidence/' + p.name) for p in sorted((ARTIFACTS / 'evidence').glob('*')) if p.is_file()]
    with zipfile.ZipFile(ARTIFACTS / 'Longwalk-Shared-Village-06-Server.zip', 'w', zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
        for path, name in files:
            archive.write(path, name)
    packages = sorted(p for p in ARTIFACTS.iterdir() if p.suffix in ['.zip', '.tar'])
    (ARTIFACTS / 'SHA256SUMS.txt').write_text(''.join(digest(p) + '  ' + p.name + '\n' for p in packages))
    print('Server bundle updated; tested image bytes retained')


if __name__ == '__main__':
    main()
