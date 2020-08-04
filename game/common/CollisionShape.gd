tool
extends CollisionShape

export (Mesh) var mesh = null setget set_mesh
func set_mesh(newmesh):
	if newmesh != mesh:
		mesh = newmesh
		remake_shape()

enum MeshMode {CONVEX, TRIMESH}
export (MeshMode) var mesh_mode = MeshMode.CONVEX setget set_mesh_mode
func set_mesh_mode(newmode):
	if newmode != mesh_mode: 
		mesh_mode = newmode
		remake_shape()

func remake_shape():
	if !mesh: return
	set_shape(
		mesh.create_convex_shape() if mesh_mode == MeshMode.CONVEX \
		else mesh.create_trimesh_shape())
