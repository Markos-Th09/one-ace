from pathlib import Path
import json
from PIL import Image

root = Path(__file__).resolve().parents[1]
width, height = Image.open(root / 'assets/black_chipper/sprite_sheet.png').size
cell_w, cell_h = width / 4, height / 5
parts = ['[gd_resource type="SpriteFrames" format=3]', '[ext_resource type="Texture2D" path="res://assets/black_chipper/sprite_sheet.png" id="1"]']
for row in range(5):
    for col in range(4):
        index = row * 4 + col
        parts += [f'[sub_resource type="AtlasTexture" id="Frame{index}"]', 'atlas = ExtResource("1")', f'region = Rect2({col * cell_w}, {row * cell_h}, {cell_w}, {cell_h})']
animations = []
for row, (name, speed, loop) in enumerate([('idle', 5, True), ('walk', 8, True), ('lunge', 8, False), ('spin', 8, True), ('death', 6, False)]):
    frames = ', '.join('{"duration": 1.0, "texture": SubResource("Frame%d")}' % (row * 4 + col) for col in range(4))
    animations.append('{"name": &"%s", "speed": %s, "loop": %s, "frames": [%s]}' % (name, speed, str(loop).lower(), frames))
parts += ['[resource]', 'animations = [' + ',\n'.join(animations) + ']']
(root / 'assets/black_chipper/animations.tres').write_text('\n'.join(parts) + '\n')
batch = {'scene_path': 'scenes/casino_level.tscn', 'actions': [
    {'type': 'instantiate_scene', 'instance_scene_path': 'objects/boss_arena.tscn', 'node_name': 'BossArena'},
    {'type': 'instantiate_scene', 'instance_scene_path': 'objects/checkpoint.tscn', 'node_name': 'Checkpoint3', 'properties': {'position': {'__type': 'Vector2', 'x': 3370, 'y': 523}, 'checkpoint_number': 3}},
    {'type': 'configure_node', 'node_path': 'root/Enemies/Crusher2', 'properties': {'position': {'__type': 'Vector2', 'x': 2850, 'y': 430}}},
    {'type': 'configure_node', 'node_path': 'root/FinishSign', 'properties': {'text': 'BEAT BLACK CHIPPER\nTO CASH OUT >>'}},
]}
(root / 'tools/boss_scene_batch.json').write_text(json.dumps(batch))
