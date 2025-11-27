import haxe.Json;
import StringTools;
#if sys
import sys.FileSystem;
import sys.io.File;
#end

class Data {
    static final sceneData = '
    { "id": "fps_arena_no_csg_scene", "type": "jdw.scene",
      "nodes": [
        { "id": "ground", "asset": "arena_ground", "pos": [0, 0, 0] },
        { "id": "walls", "asset": "arena_walls", "pos": [0, 0, 0] },
        { "id": "building", "asset": "arena_building", "pos": [0, 2, 0] },
        { "id": "ramp", "asset": "arena_ramp", "pos": [15, 1.5, -15], "rot": [20, 0, 0] },
        { "id": "platform", "asset": "arena_platform", "pos": [15, 4, -8] },
        { "id": "obstacle_box_1", "asset": "arena_obstacle_box", "pos": [-15, 1, 15] },
        { "id": "obstacle_cylinder_1", "asset": "arena_obstacle_cylinder", "pos": [15, 1.5, 15] }
      ]
    }';

    static final arenaData = '
    {
      "id": "fps_arena_geometry_no_csg",
      "type": "jda.asset",
      "kind": "sdf_library",
      "data": {
        "arena_ground": { "kind": "sdf_primitive", "data": { "primitive_type": "box", "size": [50, 0.5, 50], "material": "mat_ground_grey" }, "pos": [0, -0.25, 0] },
        "arena_walls": { "kind": "sdf_group", "children": [
          { "kind": "sdf_primitive", "data": { "primitive_type": "box", "size": [50, 5, 1], "material": "mat_wall_blue" }, "pos": [0, 2.5, 24.5] },
          { "kind": "sdf_primitive", "data": { "primitive_type": "box", "size": [50, 5, 1], "material": "mat_wall_blue" }, "pos": [0, 2.5, -24.5] },
          { "kind": "sdf_primitive", "data": { "primitive_type": "box", "size": [1, 5, 50], "material": "mat_wall_blue" }, "pos": [24.5, 2.5, 0] },
          { "kind": "sdf_primitive", "data": { "primitive_type": "box", "size": [1, 5, 50], "material": "mat_wall_blue" }, "pos": [-24.5, 2.5, 0] }
        ]},
        "arena_building": { "kind": "sdf_group", "children": [
          { "kind": "sdf_primitive", "data": { "primitive_type": "box", "size": [20, 4, 15], "material": "mat_wall_blue" } },
          { "kind": "sdf_primitive", "data": { "primitive_type": "box", "size": [18, 3.5, 3], "material": "mat_wall_blue" }, "pos": [0, 0, 0] },
          { "kind": "sdf_primitive", "data": { "primitive_type": "box", "size": [6, 3.5, 10], "material": "mat_wall_blue" }, "pos": [5, 0, -2] },
          { "kind": "sdf_primitive", "data": { "primitive_type": "box", "size": [6, 3.5, 10], "material": "mat_wall_blue" }, "pos": [-5, 0, 2] }
        ]},
        "arena_ramp": { "kind": "sdf_primitive", "data": { "primitive_type": "box", "size": [4, 0.2, 12], "material": "mat_ground_grey" } },
        "arena_platform": { "kind": "sdf_primitive", "data": { "primitive_type": "box", "size": [8, 0.5, 8], "material": "mat_ground_grey" } },
        "arena_obstacle_box": { "kind": "sdf_primitive", "data": { "primitive_type": "box", "size": [4, 2, 4], "material": "mat_obstacle_red" } },
        "arena_obstacle_cylinder": { "kind": "sdf_primitive", "data": { "primitive_type": "cylinder", "height": 3, "radius": 2, "material": "mat_obstacle_red" } }
      }
    }';

    static final materialsData = '
    {
      "id": "materials_fps_no_csg",
      "type": "jda.asset",
      "kind": "material_list",
      "data": [
        { "id": "mat_ground_grey", "shader": "simple_lit_shader", "parameters": { "baseColor": [0.3, 0.3, 0.3] } },
        { "id": "mat_wall_blue", "shader": "simple_lit_shader", "parameters": { "baseColor": [0.1, 0.1, 0.6] } },
        { "id": "mat_obstacle_red", "shader": "simple_lit_shader", "parameters": { "baseColor": [0.7, 0.1, 0.1] } }
      ]
    }';

    static final loaded = (function() {
        var fromFiles = loadFromFiles();
        return fromFiles != null ? fromFiles : loadFallback();
    })();

    public static final scene:Dynamic = loaded.scene;
    public static final assets:Map<String, Dynamic> = loaded.assets;
    public static final materials:Dynamic = loaded.materials;

    static function loadFromFiles():{ scene:Dynamic, assets:Map<String, Dynamic>, materials:Dynamic } {
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
                        case "jda.asset": if (parsed.id != null) outAssets.set(parsed.id, parsed);
                        default:
                    }
                } catch (e:Dynamic) {}
            }
        }
        if (outScene != null && outAssets.keys().hasNext()) {
            var mats = outAssets.exists("materials_fps_no_csg") ? outAssets.get("materials_fps_no_csg") : null;
            return { scene: outScene, assets: outAssets, materials: mats };
        }
        #end
        return null;
    }

    static function loadFallback():{ scene:Dynamic, assets:Map<String, Dynamic>, materials:Dynamic } {
        var m = new Map<String, Dynamic>();
        var arena = parse(arenaData);
        m.set(arena.id, arena);
        var mats = parse(materialsData);
        m.set(mats.id, mats);
        return { scene: parse(sceneData), assets: m, materials: mats };
    }

    static inline function parse(raw:String):Dynamic {
        return Json.parse(raw);
    }
}
