"""Bake the real GLB centerline into headless route height data.
Run from repository root with Python and NumPy. No generated art is modified.
Samples the top triangle intersection along the walkway, excluding parapets.
The GLB is a single identity-transformed mesh; reject a different structure.
"""
import numpy as np,struct,json,hashlib
from pathlib import Path
b=open('prototypes/two_rivers/assets/bridge.glb','rb').read();n,t=struct.unpack_from('<II',b,12);j=json.loads(b[20:20+n]);blob=b[28+n:]
assert len(j['nodes']) == 1 and j['nodes'][0]['matrix'] == [1.0,0.0,0.0,0.0,0.0,1.0,0.0,0.0,0.0,0.0,1.0,0.0,0.0,0.0,0.0,1.0]
assert len(j['meshes'][0]['primitives']) == 1
def arr(i):
 a=j['accessors'][i];v=j['bufferViews'][a['bufferView']];dt={5126:'f4',5125:'u4',5123:'u2'}[a['componentType']];ct={'VEC3':3,'SCALAR':1}[a['type']];return np.frombuffer(blob,dtype=dt,count=a['count']*ct,offset=v.get('byteOffset',0)+a.get('byteOffset',0)).reshape(a['count'],ct)
p=j['meshes'][0]['primitives'][0];v=arr(p['attributes']['POSITION']).copy();idx=arr(p['indices']).reshape(-1,3);lo=v.min(axis=0);hi=v.max(axis=0);v[:,0]-=(lo[0]+hi[0])/2;v[:,2]-=(lo[2]+hi[2])/2;v[:,1]-=lo[1];v*=24/(hi[0]-lo[0]);tri=v[idx];a=tri[:,0];u=tri[:,1]-a;w=tri[:,2]-a;den=u[:,0]*w[:,2]-u[:,2]*w[:,0];good=np.abs(den)>1e-8
def height(x,z):
 dx=x-a[:,0];dz=z-a[:,2];s=np.divide(dx*w[:,2]-dz*w[:,0],den,out=np.zeros_like(den),where=good);t=np.divide(u[:,0]*dz-u[:,2]*dx,den,out=np.zeros_like(den),where=good);mask=good&(s>=0)&(t>=0)&(s+t<=1);y=a[:,1]+s*u[:,1]+t*w[:,1];return float(y[mask].max()) if mask.any() else None
if __name__=='__main__':
 samples=[height(float(x),0.0) for x in np.arange(-12,12.001,0.25)]
 # Extreme tips may lack a centerline triangle and lie below terrain anyway.
 assert all(y is not None for y in samples[1:-1])
 samples=[0.0 if y is None else y for y in samples]
 gd = """extends RefCounted

# Baked from bridge.glb centerline triangles by reference/bake-bridge-profile.py.
# Heights use a 24m span with its bottom at zero, before placement offset.
# Source SHA256: SOURCE_HASH
const MAIN_OFFSET := -1.2
const SMALL_OFFSET := -0.6
const STEP := 0.25
const HEIGHTS := [SAMPLES]

static func deck_height(distance: float, small: bool) -> float:
 var scale_factor := 0.5 if small else 1.0
 # The short bridge's 90 degree yaw maps local +X to world -Z.
 var local_distance := -distance / scale_factor if small else distance
 if absf(local_distance) >= 12.0:
  return 0.0
 var index := (local_distance + 12.0) / STEP
 var lower := int(floor(index))
 var sampled := lerpf(HEIGHTS[lower], HEIGHTS[lower + 1], index - lower)
 return maxf(0.0, sampled * scale_factor + (SMALL_OFFSET if small else MAIN_OFFSET))
"""
 gd=gd.replace('SOURCE_HASH',hashlib.sha256(b).hexdigest()).replace('SAMPLES',', '.join(f'{v:.6f}' for v in samples))
 Path('prototypes/two_rivers/src/sim/bridge_profile.gd').write_text(gd)
 assert abs(samples[48]-1.2-1.527)<0.002
 print('Baked 97 centerline samples. Main center:',samples[48]-1.2,'short center:',samples[48]*0.5-0.6)
 for x in [-11,-8,0,8,11]:
  print('Main x',x,'deck',height(x,0)-1.2,'route',max(0,height(x,0)-1.2))
