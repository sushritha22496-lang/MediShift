import bpy
import bmesh
import math

def clear_scene():
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    for block in list(bpy.data.meshes):
        if block.users == 0:
            bpy.data.meshes.remove(block)

def add_material(name, color, roughness=0.5, metallic=0.0):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (color[0], color[1], color[2], 1.0)
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Metallic"].default_value = metallic
    return mat

def add_subsurf(obj, levels=2):
    mod = obj.modifiers.new(name="Subsurf", type='SUBSURF')
    mod.levels = levels
    mod.render_levels = levels

def apply_all_modifiers(obj):
    bpy.context.view_layer.objects.active = obj
    for mod in list(obj.modifiers):
        bpy.ops.object.modifier_apply(modifier=mod.name)

def shade_smooth(obj):
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.ops.object.shade_smooth()

clear_scene()

skin_mat = add_material("Skin", (0.82, 0.2, 0.04), roughness=0.6)
face_mat = add_material("Face", (0.88, 0.32, 0.09), roughness=0.5)
gold_mat = add_material("Gold", (0.85, 0.66, 0.12), roughness=0.2, metallic=0.9)
wood_mat = add_material("Wood", (0.35, 0.2, 0.08), roughness=0.7)
eye_mat = add_material("Eye", (0.02, 0.02, 0.02), roughness=0.2)

# ── Torso ──────────────────────────────────────────────────────────────────
bpy.ops.mesh.primitive_cylinder_add(vertices=14, radius=0.38, depth=0.95, location=(0, 0, 1.0))
torso = bpy.context.object
torso.name = "Torso"
me = torso.data
bm = bmesh.new()
bm.from_mesh(me)
bm.verts.ensure_lookup_table()
for v in bm.verts:
    if v.co.z > 0.3:
        v.co.x *= 1.12
        v.co.y *= 1.12
    elif v.co.z < -0.3:
        v.co.x *= 0.78
        v.co.y *= 0.78
bm.to_mesh(me)
bm.free()
add_subsurf(torso, 2)
apply_all_modifiers(torso)
shade_smooth(torso)
torso.data.materials.append(skin_mat)

# ── Head ───────────────────────────────────────────────────────────────────
bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=3, radius=0.3, location=(0, 0.03, 1.85))
head = bpy.context.object
head.name = "Head"
head.scale = (1.0, 1.05, 0.95)
add_subsurf(head, 1)
apply_all_modifiers(head)
shade_smooth(head)
head.data.materials.append(face_mat)

# Snout
bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=0.15, location=(0, 0.32, 1.72))
snout = bpy.context.object
snout.name = "Snout"
snout.scale = (0.85, 1.1, 0.8)
add_subsurf(snout, 1)
apply_all_modifiers(snout)
shade_smooth(snout)
snout.data.materials.append(face_mat)

# Ears
for side, sign in [("L", -1), ("R", 1)]:
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=0.13, location=(sign * 0.32, 0.0, 1.98))
    ear = bpy.context.object
    ear.name = f"Ear{side}"
    ear.scale = (0.35, 1.0, 1.0)
    add_subsurf(ear, 1)
    apply_all_modifiers(ear)
    shade_smooth(ear)
    ear.data.materials.append(face_mat)

# Eyes
for side, sign in [("L", -1), ("R", 1)]:
    bpy.ops.mesh.primitive_uv_sphere_add(segments=10, ring_count=8, radius=0.045, location=(sign * 0.12, 0.28, 1.88))
    eye = bpy.context.object
    eye.name = f"Eye{side}"
    shade_smooth(eye)
    eye.data.materials.append(eye_mat)

# ── Limb builder (tapered, jointed capsule-ish) ─────────────────────────────
def build_limb(name, base_loc, length, radius_top, radius_bottom, bend_deg, mat):
    bpy.ops.mesh.primitive_cylinder_add(vertices=10, radius=radius_top, depth=length, location=base_loc)
    obj = bpy.context.object
    obj.name = name
    me = obj.data
    bm = bmesh.new()
    bm.from_mesh(me)
    bm.verts.ensure_lookup_table()
    half = length / 2.0
    for v in bm.verts:
        t = (v.co.z + half) / length  # 0 at bottom, 1 at top
        scale = radius_bottom / radius_top + (1.0 - radius_bottom / radius_top) * t
        v.co.x *= scale
        v.co.y *= scale
    bmesh.ops.bevel(bm, geom=list(bm.verts), offset=radius_top * 0.6, segments=3, affect='VERTICES')
    bm.to_mesh(me)
    bm.free()
    add_subsurf(obj, 2)
    apply_all_modifiers(obj)
    shade_smooth(obj)
    obj.rotation_euler[0] = math.radians(bend_deg)
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=False)
    obj.data.materials.append(mat)
    return obj

left_arm = build_limb("ArmL", (-0.5, 0, 1.10), 0.7, 0.13, 0.09, 8, skin_mat)
right_arm = build_limb("ArmR", (0.5, 0, 1.10), 0.7, 0.13, 0.09, -8, skin_mat)
left_leg = build_limb("LegL", (-0.18, 0, 0.45), 0.85, 0.17, 0.12, 0, skin_mat)
right_leg = build_limb("LegR", (0.18, 0, 0.45), 0.85, 0.17, 0.12, 0, skin_mat)

# ── Tail (curve with bevel, tapered) ────────────────────────────────────────
curve_data = bpy.data.curves.new('TailCurve', type='CURVE')
curve_data.dimensions = '3D'
spline = curve_data.splines.new('BEZIER')
spline.bezier_points.add(3)
pts = [
    (0, -0.35, 1.0, 0.09),
    (0, -0.75, 1.15, 0.075),
    (0, -0.95, 1.55, 0.05),
    (0, -0.85, 1.95, 0.02),
]
for i, (x, y, z, r) in enumerate(pts):
    bp = spline.bezier_points[i]
    bp.co = (x, y, z)
    bp.handle_left_type = 'AUTO'
    bp.handle_right_type = 'AUTO'
    bp.radius = r / 0.09
curve_data.bevel_depth = 0.09
curve_data.bevel_resolution = 4
curve_data.use_fill_caps = True
tail_obj = bpy.data.objects.new("Tail", curve_data)
bpy.context.collection.objects.link(tail_obj)
bpy.context.view_layer.objects.active = tail_obj
bpy.ops.object.select_all(action='DESELECT')
tail_obj.select_set(True)
bpy.ops.object.convert(target='MESH')
shade_smooth(tail_obj)
tail_obj.data.materials.append(skin_mat)

# ── Gada (mace): bumpy head via displacement + handle ───────────────────────
bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=3, radius=0.24, location=(0.62, 0.05, 1.90))
gada_head = bpy.context.object
gada_head.name = "GadaHead"
tex = bpy.data.textures.new("GadaBumps", type='VORONOI')
tex.noise_scale = 0.35
disp = gada_head.modifiers.new(name="Bumps", type='DISPLACE')
disp.texture = tex
disp.strength = 0.035
add_subsurf(gada_head, 2)
apply_all_modifiers(gada_head)
shade_smooth(gada_head)
gada_head.data.materials.append(gold_mat)

bpy.ops.mesh.primitive_cylinder_add(vertices=10, radius=0.045, depth=0.85, location=(0.62, 0.05, 1.47))
gada_handle = bpy.context.object
gada_handle.name = "GadaHandle"
shade_smooth(gada_handle)
gada_handle.data.materials.append(wood_mat)

# ── Hierarchy: pivots for arms/legs/gada, face parts under head ────────────
def make_empty(name, location):
    e = bpy.data.objects.new(name, None)
    e.empty_display_size = 0.05
    e.location = location
    bpy.context.collection.objects.link(e)
    return e

def parent_keep_transform(child, parent):
    bpy.context.view_layer.update()
    bpy.ops.object.select_all(action='DESELECT')
    child.select_set(True)
    parent.select_set(True)
    bpy.context.view_layer.objects.active = parent
    bpy.ops.object.parent_set(type='OBJECT', keep_transform=True)
    bpy.context.view_layer.update()

model_root = make_empty("Model", (0, 0, 0))
for obj in (torso,):
    parent_keep_transform(obj, model_root)

for obj in (snout, bpy.data.objects["EarL"], bpy.data.objects["EarR"],
            bpy.data.objects["EyeL"], bpy.data.objects["EyeR"]):
    parent_keep_transform(obj, head)
parent_keep_transform(head, torso)

left_arm_pivot = make_empty("LeftArmPivot", (-0.5, 0.0, 1.45))
parent_keep_transform(left_arm, left_arm_pivot)
parent_keep_transform(left_arm_pivot, model_root)

gada_pivot = make_empty("GadaPivot", (0.5, 0.0, 1.45))
parent_keep_transform(right_arm, gada_pivot)
parent_keep_transform(gada_head, gada_pivot)
parent_keep_transform(gada_handle, gada_pivot)
parent_keep_transform(gada_pivot, model_root)

left_leg_pivot = make_empty("LeftLegPivot", (-0.18, 0.0, 0.87))
parent_keep_transform(left_leg, left_leg_pivot)
parent_keep_transform(left_leg_pivot, model_root)

right_leg_pivot = make_empty("RightLegPivot", (0.18, 0.0, 0.87))
parent_keep_transform(right_leg, right_leg_pivot)
parent_keep_transform(right_leg_pivot, model_root)

parent_keep_transform(tail_obj, model_root)

# ── Export ───────────────────────────────────────────────────────────────
bpy.ops.object.select_all(action='SELECT')
export_path = "/home/user/MediShift/assets/models/hanuman.glb"
import os
os.makedirs(os.path.dirname(export_path), exist_ok=True)
bpy.ops.export_scene.gltf(
    filepath=export_path,
    export_format='GLB',
    use_selection=True,
    export_apply=True,
)
print("EXPORT_DONE:", export_path)
