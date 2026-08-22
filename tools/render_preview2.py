import bpy, math
bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)

bpy.ops.import_scene.gltf(filepath="/home/user/MediShift/assets/models/hanuman.glb")

bpy.context.scene.view_settings.view_transform = 'Standard'

bpy.ops.object.light_add(type='SUN', location=(3,-4,6))
sun = bpy.context.object
sun.data.energy = 3.0
sun.rotation_euler = (math.radians(50), 0, math.radians(35))

world = bpy.data.worlds.new("World")
world.use_nodes = True
world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.5,0.6,0.7,1)
world.node_tree.nodes["Background"].inputs["Strength"].default_value = 1.0
bpy.context.scene.world = world

# Select all mesh objects and frame with camera looking at bounding box center
mesh_objs = [o for o in bpy.data.objects if o.type == 'MESH']
import mathutils
min_co = mathutils.Vector((1e9,1e9,1e9))
max_co = mathutils.Vector((-1e9,-1e9,-1e9))
for o in mesh_objs:
    for corner in o.bound_box:
        world_co = o.matrix_world @ mathutils.Vector(corner)
        min_co.x = min(min_co.x, world_co.x); max_co.x = max(max_co.x, world_co.x)
        min_co.y = min(min_co.y, world_co.y); max_co.y = max(max_co.y, world_co.y)
        min_co.z = min(min_co.z, world_co.z); max_co.z = max(max_co.z, world_co.z)
center = (min_co + max_co) / 2
size = max_co - min_co
print("BOUNDS min:", min_co, "max:", max_co, "center:", center, "size:", size)

bpy.ops.object.camera_add(location=(center.x + 3.0, center.y - 4.0, center.z + 1.0))
cam = bpy.context.object
direction = center - cam.location
rot_quat = direction.to_track_quat('-Z', 'Y')
cam.rotation_euler = rot_quat.to_euler()
cam.data.lens = 35
bpy.context.scene.camera = cam

scene = bpy.context.scene
scene.render.engine = 'BLENDER_EEVEE'
scene.render.resolution_x = 960
scene.render.resolution_y = 720
scene.render.filepath = "/home/user/blender_preview2.png"
bpy.ops.render.render(write_still=True)
print("RENDER_DONE")
