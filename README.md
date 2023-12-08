# Godot VBG Sample Shaders

A collection of sample shaders for Godot.

## Scenes

### Post Process Ref Grid
- Scene: res://scenes/01_post_process_ref_grid_scene.tscn
- Shader: res://shaders/post_process_ref_grid.gdshader

The Post Process Ref Grid shader provides a number of options for overlaying a grid onto the
surface of the world or visualizing other data points available within post process shaders.
This shader can serve as a handy reference for how to access certain types of data within a post
process shader:
- Original pixel color
- Original pixel roughness
- Normal in view space or world space
- Pixel position in view space or world space
- Camera position in world space
	
Shader options:
- grid_mode:
  - 0: No overlay grid
  - 1: Overlay world space grid
  - 2: Overlay view space grid
- grid_origin:
  - 3D position to use for the grid origin
  - A thicker gradient band from 0..1 on each axis is applied to make the origin findable at the intersection of the bands.
- grid_scale:
  - grid_scale is many world units between each line on the grid
- depth_min:
  - When displaying depth or distance to camera, this distance will be shown as black with gradient up to depth_max.
- depth_max:
  - When displaying depth or distance to camera, this distance will be shown as white with gradient back to depth_min.
- mode:
  - 0 = Pass-Through (same as regular color)
  - 1 = Black (makes it easier to see the grid)
  - 2 = Roughness
  - 3 = World Space Normal
  - 4 = View Space Normal
  - 5 = Depth (visualization of view space z coordinate)
  - 6 = Distance to Camera
