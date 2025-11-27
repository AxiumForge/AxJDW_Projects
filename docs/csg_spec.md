# CSG + SDF Spec (Draft)

## Formål
En letvægts-DSL til CSG oven på SDF for JDW/JDA v0.1-preview: definér primitive SDF’er, kombinations-`op`, og en simple raymarch/render-profil. Mål: kunne fortolke `sdf_csg_tree` fra JDA og evaluere dem (raymarch eller boolean-bake) konsekvent.

## Primitive SDF’er
- `box`: size [x,y,z], SDF = length(max(abs(p)-size/2,0)) + min( max(abs(p)-size/2), 0 ) (standard box SDF).
- `sphere`: radius r, SDF = length(p)-r.
- `cylinder`: radius r, height h, SDF = length(p.xz)-r; clamp y til h/2 (capped cylinder).
- `pyramid`/`cone`: use standard analytical SDF (see Inigo Quilez references).
- `plane`: n·p + d.
- 2D SDF (for extrude): e.g., rectangle (size [w,h]), circle (r), etc.

## Kombinations-`op`
- `union(a,b)`: sdf = min(a,b)
- `intersect(a,b)`: sdf = max(a,b)
- `subtract(a,b)`: sdf = max(a, -b)
- `smooth_union(a,b,k)`: optional, sdf = -log(exp(-k*a)+exp(-k*b))/k
- `smooth_subtract(a,b,k)`, `smooth_intersect(a,b,k)`: standard smooth variants.

## Transform
- Hver node kan have `pos`, `rot` (deg), `scale` (uniform eller vec3). Evaluer SDF i lokal space: p_local = invTransform(p_world).

## Træstruktur (JDA `sdf_csg_tree`)
- Node: `{ op: "union"|"subtract"|"intersect"|"smooth_union"|... , children: [...] }`
- Primitive node: `{ kind: "sdf_primitive", data: { primitive_type: "...", size|radius|height, material } }`
- Nested CSG: children kan selv være `sdf_csg_tree`.
- 2D → 3D: `{ op: "extrude", source_2d_sdf: "<id>", extrude_depth: n }` → SDF(p) = sdf2d(p.xy) extruded over z (eller valgt akse).

## Raymarch profil (minimum)
- `max_steps`, `hit_epsilon`, `max_distance`, optional `shadow_steps`, `ao_steps`.
- Normal: finite diff (central diff) på SDF.
- Material: bind ved hit (brug `material`-id fra nærmeste primitive/child). Hvis mangler: fallback farve.
- Miss: return background.

## Pseudokode (evaluate CSG)
```
function evalNode(node, p):
  if node.kind == "sdf_primitive": return sdfPrimitive(node.data, p)
  if node.op == "extrude": return sdfExtrude(node, p)
  if node.op in ["union","subtract","intersect","smooth_union",...]:
    let d = opInit(node.op)
    for c in node.children:
      dc = evalNode(c, applyInvTransform(c, p))
      d = combine(node.op, d, dc, k=node.smooth_k)
    return d
```

## Referencer (klassiske SDF/CSG opskrifter)
- Inigo Quilez, “Distance functions”: http://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
- Smooth ops: http://www.iquilezles.org/www/articles/smin/smin.htm
- Heaps raymarch eksempler kan adapteres til HL/JS target.

## Anvendelse i JDW/JDA
- JDA `kind: "sdf_csg_tree"` følger dette op-sæt; primitive bruger ovenstående SDF’er.
- JDW `nodes` anvender transform (pos/rot/scale) omkring asset-SDF; raymarcher henter node-transform → asset-SDF → materialer.
- Render-profil (fra legacy standard): brug `max_steps`, `hit_epsilon`, m.v. til at styre kvalitet.

## Begrænsninger (draft)
- Ingen tekstur/normal/displacement implementeret her; kun baseColor og SDF-form.
- Ingen meshing: kræver separat marching cubes/dual contouring, hvis ønsket.
- Extrude/displace/sampler_2d kræver uv-mapping/aksevalg; her kun simple extrude (plan xy → dybde).
