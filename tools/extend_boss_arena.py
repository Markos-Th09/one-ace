from pathlib import Path
import json
root = Path(__file__).resolve().parents[1]
def vector(x, y):
    return {'__type': 'Vector2', 'x': x, 'y': y}
def save(name, scene, actions):
    (root / 'tools' / name).write_text(json.dumps({'scene_path': scene, 'actions': actions}))
save('extend_level.json', 'scenes/casino_level.tscn', [
    {'type': 'paint_tilemap', 'node_path': 'root/TileMapLayer', 'fills': [
        {'from': {'x': 60, 'y': 9}, 'to': {'x': 71, 'y': 9}, 'source_id': 0, 'atlas_coords': {'x': 0, 'y': 0}},
        {'from': {'x': 60, 'y': 10}, 'to': {'x': 71, 'y': 15}, 'source_id': 0, 'atlas_coords': {'x': 1, 'y': 0}},
    ]},
    {'type': 'configure_node', 'node_path': 'root/FinishSign', 'properties': {'position': vector(4400, 430)}},
])
save('extend_camera.json', 'objects/Player_Character/ace.tscn', [
    {'type': 'configure_node', 'node_path': 'root/Camera2D', 'properties': {'limit_right': 4608}},
])
save('extend_arena.json', 'objects/boss_arena.tscn', [
    {'type': 'configure_node', 'node_path': 'root/BlackChipper', 'properties': {'position': vector(4100, 513)}},
    {'type': 'configure_node', 'node_path': 'root/RightGate', 'properties': {'position': vector(4598, 226)}},
])
test = root / 'tests/test_boss.gd'
text = test.read_text().replace('Vector2(3720, 513)', 'Vector2(4520, 513)').replace('Vector2(3550, 513)', 'Vector2(4000, 513)').replace('Vector2(3550, 380)', 'Vector2(4000, 380)')
test.write_text(text)
