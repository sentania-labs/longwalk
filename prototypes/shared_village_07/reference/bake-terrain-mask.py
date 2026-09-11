"""Bake authored road and field weights; no random or visit-order state."""
from pathlib import Path
import re
import numpy as np
from PIL import Image

root = Path(__file__).resolve().parent.parent
source = (root / 'src/sim/landscape.gd').read_text()
roads_line = next(line for line in source.splitlines() if line.startswith('const ROADS'))
farms_line = next(line for line in source.splitlines() if line.startswith('const FARMS'))
roads = [tuple(map(float, item.split(','))) for item in re.findall(r'Vector4\(([^)]+)\)', roads_line)]
farms = [tuple(map(float, item.split(','))) for item in re.findall(r'Rect2\(([^)]+)\)', farms_line)]
size = 2048
axis = (np.arange(size, dtype=np.float32) + .5) / size * 1024 - 512
x, z = np.meshgrid(axis, axis)
out = np.zeros((size, size, 4), dtype=np.float32)
distance = np.full((size, size), 10000, dtype=np.float32)
for ax, az, bx, bz in roads:
    dx, dz = bx-ax, bz-az
    t = np.clip(((x-ax)*dx+(z-az)*dz)/(dx*dx+dz*dz), 0, 1)
    distance = np.minimum(distance, np.hypot(x-ax-t*dx,z-az-t*dz))
# Gentle worn shoulders, with broad main lanes and narrow farm access.
out[:,:,0] = np.clip((2.05-distance)/0.70, 0, 1)
for index, (fx,fz,w,h) in enumerate(farms):
    inside = np.minimum(np.minimum(x-fx, fx+w-x), np.minimum(z-fz, fz+h-z))
    edge_variation = 0.32*np.sin(x*0.39+z*0.22) + 0.20*np.sin(x*0.83-z*0.47)
    weight = np.clip((inside+edge_variation)/1.6, 0, 1)
    channel = index % 3 + 1
    out[:,:,channel] = np.maximum(out[:,:,channel], weight)
# Door paths and restrained foundation wear come from the scene's static list.
scene = (root / 'village.gd').read_text().split('func _build_arrangement()')[1].split(']:')[0]
buildings = re.findall(r'\["([a-z_]+)",Vector3\(([^)]+)\),([\d.]+),(-?[\d.]+)\]',scene)
assert len(buildings) == 19, 'Review static building list before rebaking yards'
wear = np.zeros((size,size,3),dtype=np.float32)
def segment_distance(ax,az,bx,bz):
    dx,dz=bx-ax,bz-az
    t=np.clip(((x-ax)*dx+(z-az)*dz)/max(dx*dx+dz*dz,0.001),0,1)
    return np.hypot(x-ax-t*dx,z-az-t*dz)
for name, coords, height, angle in buildings:
    cx,_,cz=map(float,coords.split(','))
    height=float(height)
    radians=np.deg2rad(float(angle))
    sx,sz=np.sin(radians),np.cos(radians)
    front=max(3.0,min(5.5,height*0.60))
    door=(cx+sx*front,cz+sz*front)
    porch=(cx+sx*(front+1.7),cz+sz*(front+1.7))
    candidates=[]
    for ax,az,bx,bz in roads:
        dx,dz=bx-ax,bz-az
        t=np.clip(((porch[0]-ax)*dx+(porch[1]-az)*dz)/(dx*dx+dz*dz),0,1)
        candidates.append((ax+t*dx,az+t*dz))
    radius=np.hypot(*porch)
    if radius > 0:
        candidates.append((porch[0]*min(radius,10)/radius,porch[1]*min(radius,10)/radius))
    target=min(candidates,key=lambda q:(q[0]-porch[0])**2+(q[1]-porch[1])**2)
    path=np.minimum(segment_distance(*door,*porch),segment_distance(*porch,*target))
    path_wear=np.clip((1.05-path)/0.55,0,1)
    apron=np.clip((2.5-np.hypot(x-door[0],z-door[1]))/1.5,0,1)*0.60
    wear[:,:,0]=np.maximum(wear[:,:,0],np.maximum(path_wear,apron))
    # Oriented rectangular contact wear stays within a meter of foundation.
    localx=(x-cx)*sz-(z-cz)*sx
    localz=(x-cx)*sx+(z-cz)*sz
    halfx=height*(0.68 if name in ('inn','cottage_wide','barn') else 0.48)
    halfz=front*0.83
    outside=np.maximum(np.abs(localx)-halfx,np.abs(localz)-halfz)
    foundation=np.clip((0.85-outside)/1.0,0,1)*0.52
    wear[:,:,1]=np.maximum(wear[:,:,1],foundation)
Image.fromarray(np.uint8(np.clip(wear,0,1)*255),'RGB').save(root/'art/terrain-wear.png')
Image.fromarray(np.uint8(np.clip(out,0,1)*255), 'RGBA').save(root/'art/terrain-control.png')
print('Baked 2048px terrain-control.png from authored landscape')
