"""Exercise the actual server HTTP surface, network client and recovery on scratch data."""
import argparse
import http.cookiejar
import json
import os
from pathlib import Path
import secrets
import shutil
import subprocess
import tempfile
import time
import urllib.error
import urllib.request

ROOT = Path(__file__).resolve().parents[1]
ENGINE = ROOT.parents[1] / 'tools/godot/godot'


def wait_for(predicate, timeout=60):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        try:
            value = predicate()
            if value:
                return value
        except (OSError, ValueError, urllib.error.URLError):
            pass
        time.sleep(.2)
    raise RuntimeError('Timed out waiting for smoke-test condition')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--url', help='Existing isolated server with LONGWALK_ADMIN_SETUP_TOKEN supplied in environment')
    parser.add_argument('--client-executable', type=Path)
    parser.add_argument('--port', type=int, default=17787)
    args = parser.parse_args()
    with tempfile.TemporaryDirectory(prefix='longwalk-admin-smoke-') as scratch:
        scratch = Path(scratch)
        token = os.environ.get('LONGWALK_ADMIN_SETUP_TOKEN') or secrets.token_hex(32)
        env = {**os.environ, 'LONGWALK_ADMIN_SETUP_TOKEN':token, 'LONGWALK_UDP_LISTEN_PORT':str(args.port),
               'LONGWALK_HTTP_LISTEN_PORT':'18887','LONGWALK_TEST_DATA':str(scratch),
               'LONGWALK_TEST_CREDENTIAL':secrets.token_hex(32),'LONGWALK_STOP_FILE':str(scratch/'stop')}
        base = args.url or 'http://127.0.0.1:18887'
        jar = http.cookiejar.CookieJar()
        client = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(jar))
        processes = []
        log = (scratch/'server.log').open('w+')
        evidence = ROOT/'build'/('smoke-chart.log' if args.url else 'smoke-admin.log')
        evidence.parent.mkdir(exist_ok=True)

        def api(path, body=None, expected=200, anonymous=False):
            request = urllib.request.Request(base+'/api/'+path,
                data=json.dumps(body).encode() if body is not None else None,
                headers={'Content-Type':'application/json','Origin':base})
            try:
                response = (urllib.request.urlopen if anonymous else client.open)(request,timeout=60)
            except urllib.error.HTTPError as error:
                response = error
            result = json.load(response)
            assert response.code == expected, (path,response.code,result)
            return result

        def action(name, arguments=None, expected=200):
            return api('action',{'action':name,'arguments':arguments or {}},expected)

        def bot(mismatch=False):
            command = [str(args.client_executable.resolve()), '--headless'] if args.client_executable else [str(ENGINE),'--headless','--path',str(ROOT)]
            process = subprocess.Popen(command + ['--script','res://test/admin_client.gd'],
                env={**env,'LONGWALK_TEST_MISMATCH':'1' if mismatch else '0'},stdout=log,stderr=log)
            processes.append(process)
            return process

        try:
            if not args.url:
                processes.append(subprocess.Popen([str(ENGINE),'--headless','--path',str(ROOT),'--','--server','--data='+str(scratch/'world')],env=env,stdout=log,stderr=log))
            wait_for(lambda: api('session'))
            for resource in ['/', '/app.js', '/style.css']:
                with urllib.request.urlopen(base+resource) as response:
                    assert len(response.read())>100
            api('status',expected=401,anonymous=True)
            api('setup',{'name':'smoke','password':secrets.token_hex(16),'bootstrap':'wrong'},403)
            password = secrets.token_hex(16)
            api('setup',{'name':'smoke','password':password,'bootstrap':token})
            assert api('session')['authenticated']
            assert api('status')['players']==[]
            release = api('release')
            action('release_settings', {'manifest_url':'https://example.invalid/releases', 'recommended_build':'', 'minimum_build':release['build'], 'admin_origin':'', 'confirmed':True})
            incompatible = bot(True)
            assert incompatible.wait(timeout=15)==0
            assert api('status')['players']==[], 'Rejected client created a character'
            traveler = bot()
            state_path = scratch/'client-state.json'
            state = wait_for(lambda: json.loads(state_path.read_text()) if state_path.exists() else None)
            assert not state['owner'] and state['role']=='', 'Ordinary profile inherited administration'
            ident = state['id']
            grant = action('ticket',{'player':ident,'role':'mod'})
            (scratch/'client-command.json').write_text(json.dumps({'action':'staff_redeem','arguments':{'code':grant['code']}}))
            wait_for(lambda: json.loads(state_path.read_text())['role']=='mod')
            (scratch/'client-command.json').write_text(json.dumps({'action':'staff','arguments':{'operation':'teleport_self','arguments':{'x':0,'z':10,'area':'outside','confirmed':True}}}))
            wait_for(lambda: abs(json.loads(state_path.read_text())['person']['position'][2]-10)<.01)
            audit = api('status')['audit']
            assert any(row['action']=='teleport_self' and row['actor']=='traveler:'+ident and row['details']['actor_player']==ident for row in audit)

            action('revoke',{'player':ident,'confirmed':True})
            wait_for(lambda: json.loads(state_path.read_text())['role']=='')
            action('skill',{'player':ident,'skill':'running','level':3},409)
            action('skill',{'player':ident,'skill':'running','level':3,'confirmed':True})
            wait_for(lambda: json.loads(state_path.read_text())['person']['practice']['running']==900)
            action('pause',{'paused':True})
            action('backup')
            backup = api('status')['backups'][-1]
            action('skill',{'player':ident,'skill':'running','level':5,'confirmed':True})
            action('restore',{'name':backup,'confirmed':True})
            assert api('status')['paused']
            wait_for(lambda: json.loads(state_path.read_text())['person']['practice']['running']==900)
            traveler.terminate(); traveler.wait(timeout=10)
            if not args.url:
                (scratch/'stop').touch(); processes[0].wait(timeout=15)
                (scratch/'stop').unlink()
                # Corrupt only this disposable world's newest checkpoint.
                records = sorted((scratch/'world').glob('state-*.json'))
                assert records
                records[-1].write_text('deliberate smoke-test corruption')
                # Simulate a world with no manually created backups.
                for saved_backup in (scratch/'world').glob('backup-*.json'):
                    saved_backup.rename(scratch/saved_backup.name)
                # An unfinished audit append must not prevent recovery.
                (scratch/'world'/'administration'/'audit-999999999999.json.pending').write_text('interrupted write')
                processes[0] = subprocess.Popen([str(ENGINE),'--headless','--path',str(ROOT),'--','--server','--data='+str(scratch/'world')],env=env,stdout=log,stderr=log)
                wait_for(lambda: api('session'))
                api('login',{'name':'smoke','password':password})
                recovery = api('status')
                assert recovery['frozen'] and not recovery['backups'] and recovery['recovery_source'].startswith('state-')
                action('restore',{'name':recovery['recovery_source'],'confirmed':True})
                assert not api('status')['frozen'] and api('status')['paused']
            api('logout',{})
            api('status',expected=401)
            print('ADMIN SMOKE PASSED: web assets, protected setup, authentication, compatibility rejection, staff grant/revoke, skill persistence, backup/restore and recovery')
        finally:
            for process in reversed(processes):
                if process.poll() is None:
                    process.terminate()
                    try: process.wait(timeout=10)
                    except subprocess.TimeoutExpired: process.kill(); process.wait()
            log.close()
            shutil.copy2(scratch/"server.log",evidence)


if __name__ == '__main__':
    main()
