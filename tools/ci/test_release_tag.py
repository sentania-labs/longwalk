"""Exercise the release guard against checkout's rewritten local tag."""
import os
from pathlib import Path
import subprocess
import tempfile

SCRIPT = Path(__file__).with_name('validate-release-tag.sh').resolve()


def git(repo, *args):
    return subprocess.check_output(['git', '-C', str(repo), *args], text=True, stderr=subprocess.DEVNULL).strip()


def main():
    with tempfile.TemporaryDirectory(prefix='longwalk-tag-test-') as scratch:
        remote = Path(scratch)/'remote'
        clone = Path(scratch)/'checkout'
        remote.mkdir()
        git(remote, 'init', '-b', 'main')
        git(remote, 'config', 'user.name', 'Release fixture')
        git(remote, 'config', 'user.email', 'fixture@example.invalid')
        git(remote, 'commit', '--allow-empty', '-m', 'Main')
        main_sha = git(remote, 'rev-parse', 'HEAD')
        git(remote, 'tag', '-a', 'v1.0.0', '-m', 'Annotated')
        git(remote, 'tag', 'v1.0.1')
        git(remote, 'checkout', '-b', 'unmerged')
        git(remote, 'commit', '--allow-empty', '-m', 'Unmerged')
        other_sha = git(remote, 'rev-parse', 'HEAD')
        git(remote, 'tag', '-a', 'v1.0.2', '-m', 'Off main')
        git(remote, 'checkout', 'main')
        git(remote, 'clone', str(remote), str(clone))
        # Reproduce checkout's commit-to-tag refspec, losing the local annotation.
        git(clone, 'fetch', '--no-tags', 'origin', f'+{main_sha}:refs/tags/v1.0.0')
        assert git(clone, 'cat-file', '-t', 'v1.0.0') == 'commit'
        cases = [('v1.0.0', main_sha, True), ('v1.0.1', main_sha, False),
                 ('v1.0.2', other_sha, False), ('v1.0.0', other_sha, False),
                 ('v1.0.9', main_sha, False), ('invalid', main_sha, False)]
        for tag, sha, accepted in cases:
            result = subprocess.run([str(SCRIPT)], cwd=clone,
                                    env={**os.environ, 'TAG': tag, 'GITHUB_SHA': sha},
                                    capture_output=True, text=True)
            assert (result.returncode == 0) == accepted, (tag, sha, result.stderr)
        print('RELEASE TAG GUARD PASSED: rewritten local annotation, lightweight, off-main, mismatched, missing and invalid tags')


if __name__ == '__main__':
    main()
