"""Run the chart and network/API smoke test in a disposable local kind cluster."""
import json
import os
from pathlib import Path
import secrets
import subprocess
import tempfile
import time
import urllib.request

ROOT = Path(__file__).resolve().parents[1]
REPO = ROOT.parents[1]

def run(*args, **kwargs):
    return subprocess.run(args, check=True, **kwargs)

def main():
    image = os.environ.get('LONGWALK_TEST_IMAGE', 'longwalk-admin07:smoke')
    cluster = 'longwalk-smoke-' + secrets.token_hex(4)
    context = 'kind-' + cluster
    token = secrets.token_hex(32)
    with tempfile.TemporaryDirectory(prefix='longwalk-chart-') as scratch:
        os.environ['KUBECONFIG'] = str(Path(scratch)/'kubeconfig')
        config = Path(scratch)/'kind.json'
        config.write_text(json.dumps({'kind':'Cluster','apiVersion':'kind.x-k8s.io/v1alpha4','nodes':[{'role':'control-plane','extraPortMappings':[{'containerPort':30777,'hostPort':17787,'listenAddress':'127.0.0.1','protocol':'UDP'}]}]}))
        forward = None
        try:
            run('kind','create','cluster','--name',cluster,'--config',str(config),'--wait','120s')
            run('kind','load','docker-image',image,'--name',cluster)
            secret = {'apiVersion':'v1','kind':'Secret','metadata':{'name':'longwalk-admin-setup'},'stringData':{'token':token}}
            run('kubectl','--context',context,'apply','-f','-',input=json.dumps(secret),text=True,stdout=subprocess.DEVNULL)
            repository, tag = image.rsplit(':',1)
            run('helm','upgrade','--install','longwalk',str(REPO/'charts/longwalk'),'--kube-context',context,'--set','image.repository='+repository,'--set','image.tag='+tag,'--set','service.type=NodePort','--set','service.nodePort=30777','--wait','--timeout','120s')
            forward = subprocess.Popen(['kubectl','--context',context,'port-forward','service/longwalk-admin','18887:8888'],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
            run('python3',str(ROOT/'tools/smoke_admin.py'),'--url','http://127.0.0.1:18887',env={**os.environ,'LONGWALK_ADMIN_SETUP_TOKEN':token})
            forward.terminate(); forward.wait(); forward=None
            run('kubectl','--context',context,'rollout','restart','deployment/longwalk')
            run('kubectl','--context',context,'rollout','status','deployment/longwalk','--timeout=120s')
            forward = subprocess.Popen(['kubectl','--context',context,'port-forward','service/longwalk-admin','18887:8888'],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
            for _ in range(100):
                try:
                    with urllib.request.urlopen('http://127.0.0.1:18887/api/session') as response:
                        assert not json.load(response)['setup'], 'Administrator account lost after pod replacement'
                    break
                except OSError: time.sleep(.2)
            else: raise RuntimeError('Admin console unavailable after restart')
            print('CHART SMOKE PASSED: non-root deployment, client/API operations, persistent administrator after pod replacement')
        except Exception:
            evidence = ROOT/'build'/'smoke-chart-cluster.log'
            with evidence.open('w') as output:
                for command in [('get','pods','-o','wide'),('describe','pods'),('logs','deployment/longwalk','--all-containers','--tail=200')]:
                    subprocess.run(['kubectl','--context',context,*command],stdout=output,stderr=output)
            raise
        finally:
            if forward:
                forward.terminate(); forward.wait()
            run('kind','delete','cluster','--name',cluster)

if __name__ == '__main__':
    main()
