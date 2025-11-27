import haxe.Json;
import StringTools;
#if sys
import sys.FileSystem;
import sys.io.File;
#end

class Data {
    // Fallback raw blobs (keeps viewer self contained if /jdw missing)
    static final sceneData = '
    {
      "id": "fps_arena_scene",
      "type": "jdw.scene",
      "nodes": [
        { "id": "main_arena", "asset": "fps_arena_geometry", "pos": [0, 0, 0] }
      ]
    }';

    static final arenaData = '
    {
      "id": "fps_arena_geometry",
      "type": "jda.asset",
      "kind": "sdf_csg_tree",
      "data": {
        "op": "union",
        "children": [
          { "id": "ground_plane", "kind": "sdf_primitive", "data": { "primitive_type": "box", "size": [50, 0.5, 50], "material": "mat_ground_grey" }, "pos": [0, -0.25, 0] },
          {
            "id": "outer_walls",
            "kind": "sdf_csg_tree",
            "data": {
              "op": "union",
              "children": [
                { "id": "wall_north", "kind": "sdf_primitive", "data": { "primitive_type": "box", "size": [50, 5, 1], "material": "mat_wall_blue" }, "pos": [0, 2.5, 24.5] },
                { "id": "wall_south", "kind": "sdf_primitive", "data": { "primitive_type": "box", "size": [50, 5, 1], "material": "mat_wall_blue" }, "pos": [0, 2.5, -24.5] },
                { "id": "wall_east", "kind": "sdf_primitive", "data": { "primitive_type": "box", "size": [1, 5, 50], "material": "mat_wall_blue" }, "pos": [24.5, 2.5, 0] },
                { "id": "wall_west", "kind": "sdf_primitive", "data": { "primitive_type": "box", "size": [1, 5, 50], "material": "mat_wall_blue" }, "pos": [-24.5, 2.5, 0] }
              ]
            }
          },
          {
            "id": "central_building",
            "kind": "sdf_csg_tree",
            "data": {
              "op": "subtract",
              "children": [
                { "id": "building_main_block", "kind": "sdf_primitive", "data": { "primitive_type": "box", "size": [20, 4, 15], "material": "mat_wall_blue" } },
                { "id": "interior_spaces", "kind": "sdf_csg_tree", "data": { "op": "union", "children": [
                  { "id": "main_corridor", "kind": "sdf_primitive", "data": { "primitive_type": "box", "size": [18, 3.5, 3] }, "pos": [0, 0, 0] },
                  { "id": "room_1", "kind": "sdf_primitive", "data": { "primitive_type": "box", "size": [6, 3.5, 10] }, "pos": [5, 0, -2] },
                  { "id": "room_2", "kind": "sdf_primitive", "data": { "primitive_type": "box", "size": [6, 3.5, 10] }, "pos": [-5, 0, 2] }
                ] } }
              ]
            },
            "pos": [0, 2, 0]
          },
          { "id": "ramp_to_platform", "kind": "sdf_primitive", "data": { "primitive_type": "box", "size": [4, 0.2, 12], "material": "mat_ground_grey" }, "pos": [15, 1.5, -15], "rot": [20, 0, 0] },
          { "id": "high_platform", "kind": "sdf_primitive", "data": { "primitive_type": "box", "size": [8, 0.5, 8], "material": "mat_ground_grey" }, "pos": [15, 4, -8] },
          { "id": "obstacle_box_1", "kind": "sdf_primitive", "data": { "primitive_type": "box", "size": [4, 2, 4], "material": "mat_obstacle_red" }, "pos": [-15, 1, 15] },
          { "id": "obstacle_cylinder_1", "kind": "sdf_primitive", "data": { "primitive_type": "cylinder", "height": 3, "radius": 2, "material": "mat_obstacle_red" }, "pos": [15, 1.5, 15] }
        ]
      }
    }';

    static final materialsData = '
    {
      "id": "materials_fps",
      "type": "jda.asset",
      "kind": "material_list",
      "data": [
        { "id": "mat_ground_grey", "shader": "simple_lit_shader", "parameters": { "baseColor": [0.3, 0.3, 0.3] } },
        { "id": "mat_wall_blue", "shader": "simple_lit_shader", "parameters": { "baseColor": [0.1, 0.1, 0.6] } },
        { "id": "mat_obstacle_red", "shader": "simple_lit_shader", "parameters": { "baseColor": [0.7, 0.1, 0.1] } },
        { "id": "mat_transparent_glass", "shader": "simple_lit_shader", "parameters": { "baseColor": [0.8, 0.9, 1.0] }, "opacity": 0.3 }
      ]
    }';

    static final simpleLitData = '
    {
      "id": "simple_lit_shader",
      "type": "jda.asset",
      "kind": "axsl_shader",
      "data": {
        "parameters": [
          { "name": "baseColor", "type": "vec3" }
        ],
        "code": {
          "fragment_shader": [
            "vec3 lightDirection = normalize(vec3(0.5, 1.0, 0.75));",
            "float ambient = 0.2;",
            "float diffuse = max(0.0, dot(surface_normal, lightDirection));",
            "vec3 finalColor = baseColor * (ambient + diffuse);",
            "return vec4(finalColor, 1.0);"
          ]
        }
      }
    }';

    static function loadFromFiles():{ scene:Dynamic, assets:Map<String, Dynamic>, materials:Dynamic, shaderSimpleLit:Dynamic } {
        #if sys
        var base = haxe.io.Path.normalize("../jdw");
        var outScene:Dynamic = null;
        var outAssets = new Map<String, Dynamic>();
        if (FileSystem.exists(base) && FileSystem.isDirectory(base)) {
            for (f in FileSystem.readDirectory(base)) {
                if (!StringTools.endsWith(f, ".json")) continue;
                var path = base + "/" + f;
                try {
                    var parsed:Dynamic = Json.parse(File.getContent(path));
                    if (parsed == null) continue;
                    switch (parsed.type) {
                        case "jdw.scene": outScene = parsed;
                        case "jda.asset":
                            if (parsed.id != null) outAssets.set(parsed.id, parsed);
                        default:
                    }
                } catch (e:Dynamic) {
                    // ignore and fall back
                }
            }
        }
        if (outScene != null && outAssets.keys().hasNext()) {
            var mats = outAssets.exists("materials_fps") ? outAssets.get("materials_fps") : null;
            var shader = outAssets.exists("simple_lit_shader") ? outAssets.get("simple_lit_shader") : null;
            return { scene: outScene, assets: outAssets, materials: mats, shaderSimpleLit: shader };
        }
        #end
        return null;
    }

    static function loadFallback():{ scene:Dynamic, assets:Map<String, Dynamic>, materials:Dynamic, shaderSimpleLit:Dynamic } {
        var m = new Map<String, Dynamic>();
        var arena = parse(arenaData);
        m.set(arena.id, arena);
        var mats = parse(materialsData);
        m.set(mats.id, mats);
        var shader = parse(simpleLitData);
        m.set(shader.id, shader);
        return { scene: parse(sceneData), assets: m, materials: mats, shaderSimpleLit: shader };
    }

    static final loaded = (function() {
        var fromFiles = loadFromFiles();
        return fromFiles != null ? fromFiles : loadFallback();
    })();

    public static final scene:Dynamic = loaded.scene;
    public static final assets:Map<String, Dynamic> = loaded.assets;
    public static final materials:Dynamic = loaded.materials;
    public static final shaderSimpleLit:Dynamic = loaded.shaderSimpleLit;

    static inline function parse(raw:String):Dynamic {
        return Json.parse(raw);
    }
}
