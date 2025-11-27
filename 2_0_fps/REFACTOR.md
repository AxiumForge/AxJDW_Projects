# REFACTOR TASKS — FPS Viewer & JDW/JDA Scene

## 1) Implement proper CSG/SDF preview
- Add raymarch preview (union/subtract/intersect) or a CPU boolean bake (voxel/mesh) so subtract actually cuts geometry.
- Respect JDW/JDA `op` tree; expose errors when `op`/children are missing or invalid.

## 2) Support 2D → 3D operations
- Handle `op:"extrude"` for 2D SDF assets (see `docs/axiumdocs_shared/sdf_2d_to_3d_techniques.md`); map to thickness + placement.
- Gracefully skip or stub `displace`/`sampler_2d` if not implemented; log unsupported ops.

## 3) Simplify render mode & visuals
- Make wireframe a debug toggle (default off); render solids by default.
- Keep primitive dimensions direct (no unit + post-scale); apply JDW `pos/rot/scale` only once.
- Tune lighting: keep dir + fill, lighter fallback; optional gamma/tonemap for visibility.

## 4) Validation & safety checks
- Validate that every `asset` reference in JDW exists in loaded JDA.
- Check sizes/radii/heights for NaN/Inf/zero; report and skip bad nodes.
- Warn when materials/shaders are missing or unsupported.

## 5) UX polish
- Camera presets (top/front/iso/reset) and sensitivity sliders for orbit/FPS.
- Optional: toggle wireframe, toggle subtract visualization, and reset FPS start.

## 6) Builds & portability
- JS build as default for portability; keep HL with `hlsdl` for native, but document GUI requirement (SDL display).
- Add a simple static server script or note for JS preview.
