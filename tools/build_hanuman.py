import bpy
import bmesh
import math
import random

random.seed(7)

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

def make_empty(name, location):
    e = bpy.data.objects.new(name, None)
    e.empty_display_size = 0.05
    e.location = location
    bpy.context.collection.objects.link(e)
    return e

def parent_keep_transform(child, parent):
    bpy.context.view_layer.update()
    child.parent = parent
    child.matrix_parent_inverse = parent.matrix_world.inverted()

clear_scene()

skin_mat = add_material("Skin", (0.82, 0.2, 0.04), roughness=0.6)
face_mat = add_material("Face", (0.88, 0.32, 0.09), roughness=0.5)
gold_mat = add_material("Gold", (0.85, 0.66, 0.12), roughness=0.2, metallic=0.9)
wood_mat = add_material("Wood", (0.35, 0.2, 0.08), roughness=0.7)
eye_mat = add_material("Eye", (0.02, 0.02, 0.02), roughness=0.15)
sclera_mat = add_material("Sclera", (0.85, 0.8, 0.7), roughness=0.35)
hair_mat = add_material("Hair", (0.06, 0.04, 0.03), roughness=0.85)

# ── Torso (muscled: broad shoulders, chest, abs, tapered waist) ────────────
bpy.ops.mesh.primitive_cylinder_add(vertices=20, radius=0.38, depth=0.95, location=(0, 0, 1.0))
torso = bpy.context.object
torso.name = "Torso"
me = torso.data
bm = bmesh.new()
bm.from_mesh(me)
bm.verts.ensure_lookup_table()
for v in bm.verts:
    z = v.co.z
    front = max(v.co.y, 0.0)
    # broad shoulders / traps
    if z > 0.3:
        v.co.x *= 1.24
        v.co.y *= 1.24
    # chest bulge (pecs) - frontal only
    elif 0.02 <= z <= 0.32 and front > 0.05:
        t = max(0.0, 1.0 - abs(z - 0.17) / 0.16)
        bulge = 1.0 + 0.55 * t
        v.co.x *= bulge
        v.co.y *= bulge
    # abdominal definition - frontal ridged bands
    elif -0.32 <= z < 0.02 and front > 0.08:
        ridge = 0.5 + 0.5 * math.cos(z * 34.0)
        scale = 1.0 - 0.14 * ridge
        v.co.x *= scale
        v.co.y *= scale
    # tapered waist
    elif z < -0.32:
        v.co.x *= 0.72
        v.co.y *= 0.72
bm.to_mesh(me)
bm.free()
add_subsurf(torso, 1)
apply_all_modifiers(torso)
shade_smooth(torso)
torso.data.materials.append(skin_mat)

# Neck: bridges torso top to head so subsurf shrinkage can't leave a gap
bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=0.19, depth=0.34, location=(0, 0.02, 1.55))
neck = bpy.context.object
neck.name = "Neck"
add_subsurf(neck, 1)
apply_all_modifiers(neck)
shade_smooth(neck)
neck.data.materials.append(skin_mat)

# ── Head ───────────────────────────────────────────────────────────────────
bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=3, radius=0.3, location=(0, 0.03, 1.78))
head = bpy.context.object
head.name = "Head"
head.scale = (1.0, 1.03, 0.92)
add_subsurf(head, 1)
apply_all_modifiers(head)
shade_smooth(head)
head.data.materials.append(face_mat)

# Chin/jaw tip for a more defined human-like jawline
bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=0.13, location=(0, 0.22, 1.55))
chin = bpy.context.object
chin.name = "Chin"
chin.scale = (0.8, 0.9, 0.7)
add_subsurf(chin, 1)
apply_all_modifiers(chin)
shade_smooth(chin)
chin.data.materials.append(face_mat)

# Snout / muzzle
bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=0.15, location=(0, 0.32, 1.67))
snout = bpy.context.object
snout.name = "Snout"
snout.scale = (0.85, 1.1, 0.8)
add_subsurf(snout, 1)
apply_all_modifiers(snout)
shade_smooth(snout)
snout.data.materials.append(face_mat)

# Brow ridge (gives the face an expressive, human-like brow)
for side, sign in [("L", -1), ("R", 1)]:
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=0.09, location=(sign * 0.13, 0.27, 1.88))
    brow = bpy.context.object
    brow.name = f"Brow{side}"
    brow.scale = (1.3, 0.55, 0.5)
    apply_all_modifiers(brow)
    shade_smooth(brow)
    brow.data.materials.append(face_mat)

# Ears
for side, sign in [("L", -1), ("R", 1)]:
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=0.13, location=(sign * 0.32, 0.0, 1.91))
    ear = bpy.context.object
    ear.name = f"Ear{side}"
    ear.scale = (0.35, 1.0, 1.0)
    add_subsurf(ear, 1)
    apply_all_modifiers(ear)
    shade_smooth(ear)
    ear.data.materials.append(face_mat)

# Eyes: sclera + pupil for a clearer, human-like gaze
for side, sign in [("L", -1), ("R", 1)]:
    bpy.ops.mesh.primitive_uv_sphere_add(segments=10, ring_count=8, radius=0.06, location=(sign * 0.12, 0.26, 1.81))
    sclera = bpy.context.object
    sclera.name = f"EyeWhite{side}"
    shade_smooth(sclera)
    sclera.data.materials.append(sclera_mat)

    bpy.ops.mesh.primitive_uv_sphere_add(segments=8, ring_count=6, radius=0.035, location=(sign * 0.12, 0.31, 1.815))
    eye = bpy.context.object
    eye.name = f"Eye{side}"
    shade_smooth(eye)
    eye.data.materials.append(eye_mat)

# Light beard tufts along the jaw/chin
beard_objs = []
beard_points = [(-0.09, 0.24, 1.51), (0.0, 0.27, 1.48), (0.09, 0.24, 1.51), (-0.04, 0.26, 1.53), (0.04, 0.26, 1.53)]
for i, (bx, by, bz) in enumerate(beard_points):
    bpy.ops.mesh.primitive_cone_add(vertices=6, radius1=0.025, radius2=0.004, depth=0.09,
                                     location=(bx, by + 0.02, bz - 0.04))
    tuft = bpy.context.object
    tuft.name = f"BeardTuft{i}"
    tuft.rotation_euler = (math.radians(100 + random.uniform(-8, 8)), 0, random.uniform(-0.2, 0.2))
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=False)
    shade_smooth(tuft)
    tuft.data.materials.append(hair_mat)
    beard_objs.append(tuft)

# ── Limb builder (tapered + muscle bulges) ──────────────────────────────────
def build_limb(name, base_loc, length, radius_top, radius_bottom, bend_deg, mat, bulges=None):
    bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=radius_top, depth=length, location=base_loc)
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
        if bulges:
            for (tc, width, strength) in bulges:
                scale *= 1.0 + strength * math.exp(-((t - tc) / width) ** 2)
        v.co.x *= scale
        v.co.y *= scale
    bmesh.ops.bevel(bm, geom=list(bm.verts), offset=radius_top * 0.6, segments=3, affect='VERTICES')
    bm.to_mesh(me)
    bm.free()
    add_subsurf(obj, 1)
    apply_all_modifiers(obj)
    shade_smooth(obj)
    obj.rotation_euler[0] = math.radians(bend_deg)
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=False)
    obj.data.materials.append(mat)
    return obj

BICEP_BULGE = [(0.72, 0.16, 0.95)]
QUAD_CALF_BULGE = [(0.82, 0.14, 0.8), (0.22, 0.15, 0.6)]

left_arm = build_limb("ArmL", (-0.5, 0, 1.10), 0.7, 0.14, 0.095, 8, skin_mat, bulges=BICEP_BULGE)
right_arm = build_limb("ArmR", (0.5, 0, 1.10), 0.7, 0.14, 0.095, -8, skin_mat, bulges=BICEP_BULGE)
left_leg = build_limb("LegL", (-0.18, 0, 0.45), 0.85, 0.19, 0.13, 0, skin_mat, bulges=QUAD_CALF_BULGE)
right_leg = build_limb("LegR", (0.18, 0, 0.45), 0.85, 0.19, 0.13, 0, skin_mat, bulges=QUAD_CALF_BULGE)

# Sparse forearm / shin hair tufts ("light hair on body")
def add_hair_tufts(prefix, base_pos, count, spread, parent_hint):
    objs = []
    for i in range(count):
        ox = random.uniform(-spread, spread)
        oy = random.uniform(-0.02, 0.06)
        oz = random.uniform(-spread, spread)
        bpy.ops.mesh.primitive_cone_add(vertices=5, radius1=0.014, radius2=0.002, depth=0.05,
                                         location=(base_pos[0] + ox, base_pos[1] + 0.08 + oy, base_pos[2] + oz))
        t = bpy.context.object
        t.name = f"{prefix}{i}"
        t.rotation_euler = (math.radians(80 + random.uniform(-15, 15)), 0, random.uniform(-0.3, 0.3))
        bpy.ops.object.transform_apply(location=False, rotation=True, scale=False)
        shade_smooth(t)
        t.data.materials.append(hair_mat)
        objs.append(t)
    return objs

chest_hair = add_hair_tufts("ChestHair", (0.0, 0.30, 1.15), 4, 0.10, "torso")
forearm_hair_l = add_hair_tufts("ForearmHairL", (-0.5, 0.05, 0.85), 3, 0.06, "armL")
forearm_hair_r = add_hair_tufts("ForearmHairR", (0.5, 0.05, 0.85), 3, 0.06, "armR")
shin_hair_l = add_hair_tufts("ShinHairL", (-0.18, 0.10, 0.15), 3, 0.06, "legL")
shin_hair_r = add_hair_tufts("ShinHairR", (0.18, 0.10, 0.15), 3, 0.06, "legR")

# ── Big feet with toe definition ────────────────────────────────────────────
def build_foot(name, x_sign):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.18 * x_sign, 0.16, 0.03))
    foot = bpy.context.object
    foot.name = name
    foot.scale = (0.22, 0.48, 0.15)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    me = foot.data
    bm = bmesh.new()
    bm.from_mesh(me)
    bm.verts.ensure_lookup_table()
    for v in bm.verts:
        if v.co.y > 0:
            v.co.y *= 1.15
            v.co.x *= 0.7
    bmesh.ops.bevel(bm, geom=list(bm.verts), offset=0.035, segments=3, affect='VERTICES')
    bm.to_mesh(me)
    bm.free()
    add_subsurf(foot, 1)
    apply_all_modifiers(foot)
    shade_smooth(foot)
    foot.data.materials.append(skin_mat)

    toes = []
    for i in range(5):
        tx = (0.18 * x_sign) + (i - 2) * 0.045
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=0.035, location=(tx, 0.34, 0.02))
        toe = bpy.context.object
        toe.name = f"{name}Toe{i}"
        toe.scale = (0.85, 1.0, 0.7)
        apply_all_modifiers(toe)
        shade_smooth(toe)
        toe.data.materials.append(skin_mat)
        toes.append(toe)
    return foot, toes

foot_l, toes_l = build_foot("FootL", -1)
foot_r, toes_r = build_foot("FootR", 1)

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
bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=3, radius=0.26, location=(0.68, 0.05, 1.78))
gada_head = bpy.context.object
gada_head.name = "GadaHead"
tex = bpy.data.textures.new("GadaBumps", type='VORONOI')
tex.noise_scale = 0.35
disp = gada_head.modifiers.new(name="Bumps", type='DISPLACE')
disp.texture = tex
disp.strength = 0.04
add_subsurf(gada_head, 1)
apply_all_modifiers(gada_head)
shade_smooth(gada_head)
gada_head.data.materials.append(gold_mat)

bpy.ops.mesh.primitive_cylinder_add(vertices=10, radius=0.05, depth=0.85, location=(0.66, 0.05, 1.32))
gada_handle = bpy.context.object
gada_handle.name = "GadaHandle"
shade_smooth(gada_handle)
gada_handle.data.materials.append(wood_mat)

# Gold binding rings on the gada handle
gada_rings = []
for i, rz in enumerate([1.15, 1.32, 1.49]):
    bpy.ops.mesh.primitive_torus_add(major_radius=0.06, minor_radius=0.015, location=(0.67, 0.05, rz))
    ring = bpy.context.object
    ring.name = f"GadaRing{i}"
    shade_smooth(ring)
    ring.data.materials.append(gold_mat)
    gada_rings.append(ring)

# ── Ornaments: armlets, wristlets, anklets, waistband ───────────────────────
def make_torus(name, major_r, minor_r, location, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_torus_add(major_radius=major_r, minor_radius=minor_r, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.rotation_euler = rot
    apply_all_modifiers(obj)
    shade_smooth(obj)
    obj.data.materials.append(gold_mat)
    return obj

armlet_l = make_torus("ArmletL", 0.155, 0.025, (-0.5, 0.0, 1.30))
armlet_r = make_torus("ArmletR", 0.155, 0.025, (0.5, 0.0, 1.30))
wristlet_l = make_torus("WristletL", 0.11, 0.02, (-0.5, 0.0, 0.76))
wristlet_r = make_torus("WristletR", 0.11, 0.02, (0.5, 0.0, 0.76))
anklet_l = make_torus("AnkletL", 0.15, 0.022, (-0.18, 0.05, 0.10))
anklet_r = make_torus("AnkletR", 0.15, 0.022, (0.18, 0.05, 0.10))
waistband = make_torus("Waistband", 0.34, 0.03, (0, 0, 0.68), rot=(0, 0, 0))

# ── Hierarchy: pivots for arms/legs/gada, decorations follow their limb ────
model_root = make_empty("Model", (0, 0, 0))
parent_keep_transform(torso, model_root)

for obj in ([snout, chin, bpy.data.objects["EarL"], bpy.data.objects["EarR"],
             bpy.data.objects["EyeL"], bpy.data.objects["EyeR"],
             bpy.data.objects["EyeWhiteL"], bpy.data.objects["EyeWhiteR"],
             bpy.data.objects["BrowL"], bpy.data.objects["BrowR"]] + beard_objs):
    parent_keep_transform(obj, head)
parent_keep_transform(head, torso)

for obj in chest_hair + [waistband, neck]:
    parent_keep_transform(obj, torso)

left_arm_pivot = make_empty("LeftArmPivot", (-0.5, 0.0, 1.45))
for obj in [left_arm, armlet_l, wristlet_l] + forearm_hair_l:
    parent_keep_transform(obj, left_arm_pivot)
parent_keep_transform(left_arm_pivot, model_root)

gada_pivot = make_empty("GadaPivot", (0.5, 0.0, 1.45))
for obj in [right_arm, gada_head, gada_handle, armlet_r, wristlet_r] + forearm_hair_r + gada_rings:
    parent_keep_transform(obj, gada_pivot)
parent_keep_transform(gada_pivot, model_root)

left_leg_pivot = make_empty("LeftLegPivot", (-0.18, 0.0, 0.87))
for obj in [left_leg, foot_l, anklet_l] + toes_l + shin_hair_l:
    parent_keep_transform(obj, left_leg_pivot)
parent_keep_transform(left_leg_pivot, model_root)

right_leg_pivot = make_empty("RightLegPivot", (0.18, 0.0, 0.87))
for obj in [right_leg, foot_r, anklet_r] + toes_r + shin_hair_r:
    parent_keep_transform(obj, right_leg_pivot)
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
