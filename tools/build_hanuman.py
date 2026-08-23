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
bpy.ops.mesh.primitive_cylinder_add(vertices=36, radius=0.38, depth=0.95, location=(0, 0, 1.0))
torso = bpy.context.object
torso.name = "Torso"
me = torso.data
bm = bmesh.new()
bm.from_mesh(me)
bm.verts.ensure_lookup_table()
bm.edges.ensure_lookup_table()
vertical_edges = [e for e in bm.edges if abs(e.verts[0].co.z - e.verts[1].co.z) > 0.1]
bmesh.ops.subdivide_edges(bm, edges=vertical_edges, cuts=13)
bm.verts.ensure_lookup_table()
for v in bm.verts:
    z = v.co.z
    r = math.sqrt(v.co.x * v.co.x + v.co.y * v.co.y)
    ff = (v.co.y / r) if r > 1e-6 else 0.0
    side_f = (abs(v.co.x) / r) if r > 1e-6 else 0.0
    front = max(ff, 0.0)
    back = max(-ff, 0.0)
    scale = 1.0
    if z > 0.32:
        scale *= 1.3
    shoulder_t = max(0.0, 1.0 - abs(z - 0.29) / 0.1) * side_f
    scale *= 1.0 + 0.32 * shoulder_t
    chest_t = max(0.0, 1.0 - abs(z - 0.16) / 0.18)
    sternum_dip = 1.0 - 0.55 * math.exp(-((v.co.x) / 0.12) ** 2)
    scale *= 1.0 + 0.45 * chest_t * front * sternum_dip
    if -0.30 <= z < 0.04:
        ridge = 0.5 + 0.5 * math.cos((z - 0.04) * 22.0)
        scale *= 1.0 - 0.15 * ridge * front
    ab_t = max(0.0, 1.0 - abs(z - (-0.08)) / 0.12)
    scale *= 1.0 + 0.08 * ab_t * front
    back_t = max(0.0, 1.0 - abs(z - 0.05) / 0.4)
    scale *= 1.0 + 0.25 * back_t * back
    # shoulder-blade hints + spine groove, back only
    blade_t = max(0.0, 1.0 - abs(z - 0.18) / 0.12) * max(0.0, back - 0.35) * 1.5
    scale *= 1.0 + 0.16 * min(blade_t, 1.0)
    spine_t = max(0.0, 1.0 - abs(v.co.x) / 0.05) * back * max(0.0, 1.0 - abs(z - 0.05) / 0.3)
    scale *= 1.0 - 0.1 * spine_t
    if z < -0.32:
        scale *= 0.68
    v.co.x *= scale
    v.co.y *= scale
cap_verts = [v for v in bm.verts if abs(v.co.z) > 0.46]
interior_verts = [v for v in bm.verts if v not in cap_verts]
bmesh.ops.smooth_vert(bm, verts=interior_verts, factor=0.2, use_axis_x=True, use_axis_y=True, use_axis_z=False)
bmesh.ops.smooth_vert(bm, verts=interior_verts, factor=0.12, use_axis_x=True, use_axis_y=True, use_axis_z=True)
bm.to_mesh(me)
bm.free()
add_subsurf(torso, 2)
apply_all_modifiers(torso)
shade_smooth(torso)
torso.data.materials.append(skin_mat)

# Loincloth (dhoti wrap) around the waist
bpy.ops.mesh.primitive_cylinder_add(vertices=28, radius=0.45, depth=0.36, location=(0, 0, 0.62))
cloth = bpy.context.object
cloth.name = "Loincloth"
me = cloth.data
bm = bmesh.new()
bm.from_mesh(me)
bm.verts.ensure_lookup_table()
bm.edges.ensure_lookup_table()
cloth_vertical_edges = [e for e in bm.edges if abs(e.verts[0].co.z - e.verts[1].co.z) > 0.05]
bmesh.ops.subdivide_edges(bm, edges=cloth_vertical_edges, cuts=5)
bm.verts.ensure_lookup_table()
for v in bm.verts:
    r = math.sqrt(v.co.x * v.co.x + v.co.y * v.co.y)
    back = max(-(v.co.y / r), 0.0) if r > 1e-6 else 0.0
    bottom_t = max(0.0, min(1.0, (0.16 - v.co.z) / 0.32))
    flare = 1.0 + 0.16 * bottom_t
    v.co.x *= flare
    v.co.y *= flare
    v.co.z -= 0.09 * bottom_t * back
bm.to_mesh(me)
bm.free()
add_subsurf(cloth, 2)
apply_all_modifiers(cloth)
shade_smooth(cloth)
cloth_mat = add_material("Cloth", (0.85, 0.55, 0.08), roughness=0.75)
cloth.data.materials.append(cloth_mat)

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

# Nose with nostrils and bridge definition
bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=0.11, location=(0, 0.36, 1.75))
nose = bpy.context.object
nose.name = "Nose"
nose.scale = (0.7, 1.0, 0.9)
me = nose.data
bm = bmesh.new()
bm.from_mesh(me)
bm.verts.ensure_lookup_table()
for v in bm.verts:
    if v.co.y > 0.02:
        v.co.y *= 1.2
    if abs(v.co.x) < 0.04 and v.co.y > 0:
        v.co.x *= 0.6
bm.to_mesh(me)
bm.free()
add_subsurf(nose, 1)
apply_all_modifiers(nose)
shade_smooth(nose)
nose.data.materials.append(face_mat)

# Nostrils (small dark spheres)
for side, sign in [("L", -1), ("R", 1)]:
    bpy.ops.mesh.primitive_uv_sphere_add(segments=5, ring_count=4, radius=0.015, location=(sign * 0.027, 0.37, 1.71))
    nostril = bpy.context.object
    nostril.name = f"Nostril{side}"
    shade_smooth(nostril)
    nostril.data.materials.append(eye_mat)

# Mouth: lower lip and upper lip for expression
bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=0.06, location=(0, 0.32, 1.60))
lower_lip = bpy.context.object
lower_lip.name = "LowerLip"
lower_lip.scale = (1.2, 0.6, 0.7)
add_subsurf(lower_lip, 1)
apply_all_modifiers(lower_lip)
shade_smooth(lower_lip)
lip_mat = add_material("Lips", (0.75, 0.25, 0.15), roughness=0.4)
lower_lip.data.materials.append(lip_mat)

bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=0.052, location=(0, 0.33, 1.68))
upper_lip = bpy.context.object
upper_lip.name = "UpperLip"
upper_lip.scale = (1.2, 0.5, 0.6)
add_subsurf(upper_lip, 1)
apply_all_modifiers(upper_lip)
shade_smooth(upper_lip)
upper_lip.data.materials.append(lip_mat)

# Snout / muzzle (smaller now that nose is separated)
bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=0.12, location=(0, 0.34, 1.67))
snout = bpy.context.object
snout.name = "Snout"
snout.scale = (0.75, 0.95, 0.7)
add_subsurf(snout, 1)
apply_all_modifiers(snout)
shade_smooth(snout)
snout.data.materials.append(face_mat)

# Brow ridge (gives the face an expressive, human-like brow)
for side, sign in [("L", -1), ("R", 1)]:
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=0.1, location=(sign * 0.14, 0.28, 1.88))
    brow = bpy.context.object
    brow.name = f"Brow{side}"
    brow.scale = (1.4, 0.6, 0.55)
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
    bpy.ops.mesh.primitive_uv_sphere_add(segments=10, ring_count=8, radius=0.048, location=(sign * 0.105, 0.27, 1.815))
    sclera = bpy.context.object
    sclera.name = f"EyeWhite{side}"
    sclera.scale = (0.9, 0.7, 1.0)
    apply_all_modifiers(sclera)
    shade_smooth(sclera)
    sclera.data.materials.append(sclera_mat)

    bpy.ops.mesh.primitive_uv_sphere_add(segments=8, ring_count=6, radius=0.026, location=(sign * 0.105, 0.305, 1.815))
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
    bm.edges.ensure_lookup_table()
    limb_vertical_edges = [e for e in bm.edges if abs(e.verts[0].co.z - e.verts[1].co.z) > length * 0.3]
    bmesh.ops.subdivide_edges(bm, edges=limb_vertical_edges, cuts=9)
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
    interior = [v for v in bm.verts if abs(v.co.z) < half - 0.02]
    bmesh.ops.smooth_vert(bm, verts=interior, factor=0.25, use_axis_x=True, use_axis_y=True, use_axis_z=False)
    bm.to_mesh(me)
    bm.free()
    add_subsurf(obj, 2)
    apply_all_modifiers(obj)
    shade_smooth(obj)
    obj.rotation_euler[0] = math.radians(bend_deg)
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=False)
    obj.data.materials.append(mat)
    return obj

BICEP_BULGE = [(0.6, 0.16, 1.6), (0.2, 0.12, 0.5)]
TRICEP_BULGE = [(0.65, 0.15, 1.2)]
QUAD_CALF_BULGE = [(0.8, 0.14, 1.15), (0.3, 0.15, 0.9)]

left_arm = build_limb("ArmL", (-0.5, 0, 1.10), 0.7, 0.155, 0.10, 8, skin_mat, bulges=BICEP_BULGE)
right_arm = build_limb("ArmR", (0.5, 0, 1.10), 0.7, 0.155, 0.10, -8, skin_mat, bulges=BICEP_BULGE)
left_leg = build_limb("LegL", (-0.18, 0, 0.35), 1.05, 0.20, 0.135, 0, skin_mat, bulges=QUAD_CALF_BULGE)
right_leg = build_limb("LegR", (0.18, 0, 0.35), 1.05, 0.20, 0.135, 0, skin_mat, bulges=QUAD_CALF_BULGE)

# Arm muscle separation: triceps hint on back of arms
for side, sign in [("L", -1), ("R", 1)]:
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=0.13, location=(sign * 0.5, -0.06, 1.0))
    tricep = bpy.context.object
    tricep.name = f"Tricep{side}"
    tricep.scale = (0.9, 0.65, 0.8)
    add_subsurf(tricep, 1)
    apply_all_modifiers(tricep)
    shade_smooth(tricep)
    tricep.data.materials.append(skin_mat)

# Hands: palm + four fingers + thumb with better joint articulation
def build_hand(name, wrist_pos, x_sign, mat):
    wx, wy, wz = wrist_pos
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(wx, wy, wz))
    palm = bpy.context.object
    palm.name = f"{name}Palm"
    palm.scale = (0.115, 0.095, 0.14)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    me = palm.data
    bm = bmesh.new()
    bm.from_mesh(me)
    bm.verts.ensure_lookup_table()
    for v in bm.verts:
        if v.co.z < 0:
            v.co.z *= 0.8
    bm.to_mesh(me)
    bm.free()
    add_subsurf(palm, 1)
    apply_all_modifiers(palm)
    shade_smooth(palm)
    palm.data.materials.append(mat)

    parts = [palm]
    for i in range(4):
        fx = wx + (i - 1.5) * 0.035
        fy = wy + 0.035
        fz = wz - 0.085
        radius = 0.018 if i in (0, 3) else 0.020
        bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=radius, depth=0.125, location=(fx, fy, fz))
        finger = bpy.context.object
        finger.name = f"{name}Finger{i}"
        me = finger.data
        bm = bmesh.new()
        bm.from_mesh(me)
        bm.verts.ensure_lookup_table()
        for v in bm.verts:
            t = (v.co.z + 0.0625) / 0.125
            taper = 1.0 - 0.35 * t
            v.co.x *= taper
            v.co.y *= taper
        bm.to_mesh(me)
        bm.free()
        finger.rotation_euler = (math.radians(30), 0, 0)
        bpy.ops.object.transform_apply(location=False, rotation=True, scale=False)
        add_subsurf(finger, 1)
        apply_all_modifiers(finger)
        shade_smooth(finger)
        finger.data.materials.append(mat)
        parts.append(finger)

    bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=0.026, depth=0.10,
                                         location=(wx + x_sign * 0.062, wy + 0.015, wz + 0.02))
    thumb = bpy.context.object
    thumb.name = f"{name}Thumb"
    me = thumb.data
    bm = bmesh.new()
    bm.from_mesh(me)
    bm.verts.ensure_lookup_table()
    for v in bm.verts:
        t = (v.co.z + 0.05) / 0.10
        taper = 1.0 - 0.3 * t
        v.co.x *= taper
        v.co.y *= taper
    bm.to_mesh(me)
    bm.free()
    thumb.rotation_euler = (math.radians(20), 0, math.radians(x_sign * 55))
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=False)
    add_subsurf(thumb, 1)
    apply_all_modifiers(thumb)
    shade_smooth(thumb)
    thumb.data.materials.append(mat)
    parts.append(thumb)
    return parts

hand_l_parts = build_hand("HandL", (-0.5, 0.06, 0.6), -1, skin_mat)
hand_r_parts = build_hand("HandR", (0.5, 0.06, 0.6), 1, skin_mat)

# Deltoid caps at the shoulder sockets so the arms read as attached, not floating pillars
deltoid_l = None
deltoid_r = None
for side, sign in [("L", -1), ("R", 1)]:
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=3, radius=0.215, location=(sign * 0.45, 0.08, 1.42))
    delt = bpy.context.object
    delt.name = f"Deltoid{side}"
    delt.scale = (1.15, 0.95, 1.0)
    me = delt.data
    bm = bmesh.new()
    bm.from_mesh(me)
    bm.verts.ensure_lookup_table()
    for v in bm.verts:
        if v.co.z > 0.05:
            v.co.z *= 1.15
        if abs(v.co.x * sign) > 0.08:
            v.co.x *= 1.2
    bm.to_mesh(me)
    bm.free()
    add_subsurf(delt, 1)
    apply_all_modifiers(delt)
    shade_smooth(delt)
    delt.data.materials.append(skin_mat)
    if side == "L":
        deltoid_l = delt
    else:
        deltoid_r = delt

# Pectoral muscles: separated bulges on chest
for side, sign in [("L", -1), ("R", 1)]:
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=0.17, location=(sign * 0.20, 0.22, 1.25))
    pec = bpy.context.object
    pec.name = f"Pectoral{side}"
    pec.scale = (1.1, 1.0, 0.85)
    add_subsurf(pec, 1)
    apply_all_modifiers(pec)
    shade_smooth(pec)
    pec.data.materials.append(skin_mat)

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
forearm_hair_l = add_hair_tufts("ForearmHairL", (-0.5, 0.05, 0.95), 3, 0.05, "armL")
forearm_hair_r = add_hair_tufts("ForearmHairR", (0.5, 0.05, 0.95), 3, 0.05, "armR")
shin_hair_l = add_hair_tufts("ShinHairL", (-0.18, 0.10, -0.05), 3, 0.06, "legL")
shin_hair_r = add_hair_tufts("ShinHairR", (0.18, 0.10, -0.05), 3, 0.06, "legR")

# Calf muscles for leg definition
for side, sign in [("L", -1), ("R", 1)]:
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=0.14, location=(sign * 0.18, -0.08, -0.08))
    calf = bpy.context.object
    calf.name = f"Calf{side}"
    calf.scale = (0.85, 0.95, 1.0)
    add_subsurf(calf, 1)
    apply_all_modifiers(calf)
    shade_smooth(calf)
    calf.data.materials.append(skin_mat)

# Oblique muscles on sides of torso
for side, sign in [("L", -1), ("R", 1)]:
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=0.12, location=(sign * 0.32, 0.04, 0.85))
    oblique = bpy.context.object
    oblique.name = f"Oblique{side}"
    oblique.scale = (0.7, 1.1, 0.75)
    add_subsurf(oblique, 1)
    apply_all_modifiers(oblique)
    shade_smooth(oblique)
    oblique.data.materials.append(skin_mat)

# ── Big feet with toe definition ────────────────────────────────────────────
def build_foot(name, x_sign):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.18 * x_sign, 0.18, -0.16))
    foot = bpy.context.object
    foot.name = name
    foot.scale = (0.26, 0.56, 0.17)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    me = foot.data
    bm = bmesh.new()
    bm.from_mesh(me)
    bm.verts.ensure_lookup_table()
    for v in bm.verts:
        if v.co.y > 0:
            v.co.y *= 1.2
            v.co.x *= 0.68
        if v.co.z < 0:
            v.co.z *= 1.2
    bmesh.ops.bevel(bm, geom=list(bm.verts), offset=0.04, segments=3, affect='VERTICES')
    bm.to_mesh(me)
    bm.free()
    add_subsurf(foot, 1)
    apply_all_modifiers(foot)
    shade_smooth(foot)
    foot.data.materials.append(skin_mat)

    toes = []
    for i in range(5):
        tx = (0.18 * x_sign) + (i - 2) * 0.052
        toe_r = 0.032 if i in (0, 4) else 0.04
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=toe_r, location=(tx, 0.40, -0.18))
        toe = bpy.context.object
        toe.name = f"{name}Toe{i}"
        toe.scale = (0.8, 1.15, 0.65)
        add_subsurf(toe, 1)
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
bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=3, radius=0.26, location=(0.78, 0.05, 1.72))
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

bpy.ops.mesh.primitive_cylinder_add(vertices=10, radius=0.05, depth=0.85, location=(0.74, 0.05, 1.26))
gada_handle = bpy.context.object
gada_handle.name = "GadaHandle"
shade_smooth(gada_handle)
gada_handle.data.materials.append(wood_mat)

# Gold binding rings on the gada handle
gada_rings = []
for i, rz in enumerate([1.09, 1.26, 1.43]):
    bpy.ops.mesh.primitive_torus_add(major_radius=0.06, minor_radius=0.015, location=(0.75, 0.05, rz))
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
wristlet_l = make_torus("WristletL", 0.11, 0.02, (-0.5, 0.0, 0.68))
wristlet_r = make_torus("WristletR", 0.11, 0.02, (0.5, 0.0, 0.68))
anklet_l = make_torus("AnkletL", 0.15, 0.022, (-0.18, 0.05, -0.10))
anklet_r = make_torus("AnkletR", 0.15, 0.022, (0.18, 0.05, -0.10))
waistband = make_torus("Waistband", 0.34, 0.03, (0, 0, 0.68), rot=(0, 0, 0))

# ── Skeleton: real bones instead of empty pivots, for genuine skinned
#    animation (Godot Skeleton3D + AnimationPlayer) rather than a script-
#    driven sine-wave hack on Node3D pivots. ───────────────────────────────
BONE_RESTS = {
    "Hips": ((0, 0, 0), None),
    "Head": ((0, 0.02, 1.55), "Hips"),
    "Jaw": ((0, 0.22, 1.55), "Head"),
    "UpperArmL": ((-0.5, 0.0, 1.45), "Hips"),
    "UpperArmR": ((0.5, 0.0, 1.45), "Hips"),
    "ThighL": ((-0.18, 0.0, 0.87), "Hips"),
    "ThighR": ((0.18, 0.0, 0.87), "Hips"),
    "Tail": ((0, -0.35, 1.0), "Hips"),
}
BONE_TAIL_OFFSET = (0, 0, 0.22)

arm_data = bpy.data.armatures.new("HanumanSkeleton")
armature_obj = bpy.data.objects.new("Skeleton", arm_data)
bpy.context.collection.objects.link(armature_obj)
bpy.context.view_layer.objects.active = armature_obj
bpy.ops.object.mode_set(mode='EDIT')
edit_bones = arm_data.edit_bones
for name, (loc, parent_name) in BONE_RESTS.items():
    b = edit_bones.new(name)
    b.head = loc
    b.tail = (loc[0] + BONE_TAIL_OFFSET[0], loc[1] + BONE_TAIL_OFFSET[1], loc[2] + BONE_TAIL_OFFSET[2])
    b.use_connect = False
for name, (loc, parent_name) in BONE_RESTS.items():
    if parent_name:
        edit_bones[name].parent = edit_bones[parent_name]
bpy.ops.object.mode_set(mode='OBJECT')
for pb in armature_obj.pose.bones:
    pb.rotation_mode = 'XYZ'

def rigid_bind(obj, bone_name):
    vg = obj.vertex_groups.new(name=bone_name)
    vg.add(range(len(obj.data.vertices)), 1.0, 'REPLACE')
    mod = obj.modifiers.new(name="Armature", type='ARMATURE')
    mod.object = armature_obj
    obj.parent = armature_obj
    obj.matrix_parent_inverse = armature_obj.matrix_world.inverted()

BONE_GROUPS = {
    "Hips": [torso, neck, cloth, waistband, bpy.data.objects["PectoralL"], bpy.data.objects["PectoralR"],
             bpy.data.objects["ObliqueL"], bpy.data.objects["ObliqueR"]] + chest_hair,
    "Head": [head, bpy.data.objects["EarL"], bpy.data.objects["EarR"],
             bpy.data.objects["EyeL"], bpy.data.objects["EyeR"],
             bpy.data.objects["EyeWhiteL"], bpy.data.objects["EyeWhiteR"],
             bpy.data.objects["BrowL"], bpy.data.objects["BrowR"],
             bpy.data.objects["Nose"], bpy.data.objects["NostrilL"], bpy.data.objects["NostrilR"]] + beard_objs,
    "Jaw": [chin, snout, bpy.data.objects["LowerLip"], bpy.data.objects["UpperLip"]],
    "UpperArmL": [deltoid_l, left_arm, bpy.data.objects["TricepL"], armlet_l, wristlet_l] + forearm_hair_l + hand_l_parts,
    "UpperArmR": [deltoid_r, right_arm, bpy.data.objects["TricepR"], gada_head, gada_handle, armlet_r, wristlet_r] + forearm_hair_r + gada_rings + hand_r_parts,
    "ThighL": [left_leg, bpy.data.objects["CalfL"], foot_l, anklet_l] + toes_l + shin_hair_l,
    "ThighR": [right_leg, bpy.data.objects["CalfR"], foot_r, anklet_r] + toes_r + shin_hair_r,
    "Tail": [tail_obj],
}
for bone_name, objs in BONE_GROUPS.items():
    for obj in objs:
        rigid_bind(obj, bone_name)

# Blink capability: a shape key morph target on each eye, driven at runtime
for eyewhite_name in ("EyeWhiteL", "EyeWhiteR"):
    eyewhite = bpy.data.objects[eyewhite_name]
    eyewhite.shape_key_add(name="Basis", from_mix=False)
    blink = eyewhite.shape_key_add(name="Blink", from_mix=False)
    blink.value = 0.0
    for v in eyewhite.data.vertices:
        blink.data[v.index].co = (v.co.x, v.co.y, v.co.z * 0.04)

# Mouth opening via shape keys on lower lip and jaw
for lip_name in ("LowerLip", "UpperLip"):
    lip = bpy.data.objects[lip_name]
    lip.shape_key_add(name="Basis", from_mix=False)
    open_key = lip.shape_key_add(name="Open", from_mix=False)
    open_key.value = 0.0
    for v in lip.data.vertices:
        if lip_name == "LowerLip" and v.co.y > 0.28:
            open_key.data[v.index].co = (v.co.x, v.co.y - 0.06, v.co.z - 0.04)
        elif lip_name == "UpperLip" and v.co.y > 0.30:
            open_key.data[v.index].co = (v.co.x, v.co.y + 0.06, v.co.z + 0.04)
        else:
            open_key.data[v.index].co = v.co

# ── Animations: bone-keyframed actions, exported as separate glTF clips ────
def set_bone_rot(name, degrees_xyz, frame):
    pb = armature_obj.pose.bones[name]
    pb.rotation_euler = tuple(math.radians(d) for d in degrees_xyz)
    pb.keyframe_insert(data_path="rotation_euler", frame=frame)

def set_bone_loc(name, xyz, frame):
    pb = armature_obj.pose.bones[name]
    pb.location = xyz
    pb.keyframe_insert(data_path="location", frame=frame)

def reset_pose():
    for pb in armature_obj.pose.bones:
        pb.rotation_euler = (0, 0, 0)
        pb.location = (0, 0, 0)

def push_action_to_nla(action):
    track = armature_obj.animation_data.nla_tracks.new()
    track.name = action.name
    track.strips.new(action.name, int(action.frame_range[0]), action)
    armature_obj.animation_data.action = None

armature_obj.animation_data_create()

# Idle: gentle breathing sway
reset_pose()
action = bpy.data.actions.new("Idle")
armature_obj.animation_data.action = action
for frame in (1, 25, 49):
    sway = 0.0 if frame != 25 else 1.0
    set_bone_loc("Hips", (0, 0, 0.015 * sway), frame)
    set_bone_rot("UpperArmL", (0, 0, -2 * sway), frame)
    set_bone_rot("UpperArmR", (0, 0, 2 * sway), frame)
    set_bone_rot("Head", (0, 0, 1.5 * sway), frame)
push_action_to_nla(action)

# Walk: alternating thigh swing with counter-swinging arms
reset_pose()
action = bpy.data.actions.new("Walk")
armature_obj.animation_data.action = action
for frame, phase in ((1, 0.0), (9, 1.0), (17, 0.0), (25, -1.0), (33, 0.0)):
    set_bone_rot("ThighL", (phase * 28, 0, 0), frame)
    set_bone_rot("ThighR", (-phase * 28, 0, 0), frame)
    set_bone_rot("UpperArmL", (-phase * 20, 0, 0), frame)
    set_bone_rot("UpperArmR", (phase * 20, 0, 0), frame)
    set_bone_loc("Hips", (0, 0, abs(phase) * 0.03), frame)
push_action_to_nla(action)

# Attack: gada arm winds up and swings down
reset_pose()
action = bpy.data.actions.new("Attack")
armature_obj.animation_data.action = action
set_bone_rot("UpperArmR", (0, 0, 0), 1)
set_bone_rot("UpperArmR", (-40, 0, 15), 6)
set_bone_rot("UpperArmR", (110, 0, -20), 14)
set_bone_rot("UpperArmR", (0, 0, 0), 20)
push_action_to_nla(action)

# Roar: jaw opens, head tilts back
reset_pose()
action = bpy.data.actions.new("Roar")
armature_obj.animation_data.action = action
set_bone_rot("Jaw", (0, 0, 0), 1)
set_bone_rot("Head", (-8, 0, 0), 1)
set_bone_rot("Jaw", (35, 0, 0), 10)
set_bone_rot("Head", (-14, 0, 0), 10)
set_bone_rot("Jaw", (0, 0, 0), 22)
set_bone_rot("Head", (-8, 0, 0), 22)
push_action_to_nla(action)

reset_pose()

# Safety cleanup: delete any stray object that never got bound to the rig
# (e.g. a primitive left over from a mis-renamed/duplicated creation call) so
# it can't sneak into the export as an unbound, unmaterialed artifact.
for obj in list(bpy.data.objects):
    if obj is armature_obj:
        continue
    if obj.parent is not armature_obj:
        print("REMOVING_STRAY_OBJECT:", obj.name)
        bpy.data.objects.remove(obj, do_unlink=True)

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
    export_animations=True,
    export_nla_strips=True,
    export_morph=True,
)
print("EXPORT_DONE:", export_path)
