from pathlib import Path
import shutil
root = Path(__file__).resolve().parent.parent
context = root / 'build/server-context'
context.mkdir(parents=True, exist_ok=True)
shutil.copy2(root / 'server/Dockerfile', context / 'Dockerfile')
shutil.copy2(root.parents[1] / 'tools/godot/godot', context / 'godot')
app = context / 'app'
app.mkdir(exist_ok=True)
for name in ['boot.gd', 'boot.tscn', 'project.godot']:
    shutil.copy2(root / name, app / name)
for name in ['src', 'world']:
    shutil.copytree(root / name, app / name, dirs_exist_ok=True)
print(context)
