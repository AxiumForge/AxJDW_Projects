import haxe.Json;
import StringTools;
import haxe.io.Path;
#if sys
import sys.FileSystem;
import sys.io.File;
#end

class Data {
    // Raw JDW/JDA blobs (fallback; declared first for HL init order)
    static final sceneData = '
    {
      "id": "town_scene",
      "type": "jdw.scene",
      "nodes": [
        { "id": "ground_disk", "asset": "ground", "pos": [0, 0, 0] },
        {
          "id": "buildings",
          "nodes": [
            { "id": "house_a", "asset": "building_primitive", "pos": [-5, 0, -5] },
            { "id": "house_b", "asset": "building_hybrid", "pos": [5, 0, -2], "rot": [0, 45, 0] }
          ]
        },
        {
          "id": "nature",
          "nodes": [
            { "id": "tree_1", "asset": "tree_stylized", "pos": [8, 0, 8] },
            { "id": "tree_2", "asset": "tree_stylized", "pos": [-10, 0, 4], "scale": 1.2 }
          ]
        }
      ]
    }';

    static final groundData = '
    {
      "id": "ground",
      "type": "jda.asset",
      "kind": "sdf_primitive",
      "data": {
        "primitive_type": "cylinder",
        "height": 0.2,
        "radius": 30,
        "material": "mat_grass_green"
      }
    }';

    static final buildingPrimitiveData = '
    {
      "id": "building_primitive",
      "type": "jda.asset",
      "kind": "sdf_csg_tree",
      "data": {
        "op": "union",
        "children": [
          {
            "id": "body",
            "kind": "sdf_primitive",
            "data": {
              "primitive_type": "box",
              "size": [5, 5, 5],
              "material": "mat_wood_light"
            }
          },
          {
            "id": "roof",
            "kind": "sdf_primitive",
            "data": {
              "primitive_type": "pyramid",
              "size": [6, 3, 6],
              "material": "mat_roof_red"
            },
            "pos": [0, 5, 0]
          }
        ]
      }
    }';

    static final buildingHybridData = '
    {
      "id": "building_hybrid",
      "type": "jda.asset",
      "kind": "sdf_csg_tree",
      "data": {
        "op": "union",
        "children": [
          {
            "op": "extrude",
            "data": { "source_2d_sdf": "facade_window", "extrude_depth": 1 },
            "pos": [0, 0, -4],
            "rot": [0, 0, 0]
          },
          {
            "op": "extrude",
            "data": { "source_2d_sdf": "facade_window", "extrude_depth": 1 },
            "pos": [4, 0, 0],
            "rot": [0, 90, 0]
          },
          {
            "op": "extrude",
            "data": { "source_2d_sdf": "facade_window", "extrude_depth": 1 },
            "pos": [0, 0, 4],
            "rot": [0, 180, 0]
          },
          {
            "op": "extrude",
            "data": { "source_2d_sdf": "facade_window", "extrude_depth": 1 },
            "pos": [-4, 0, 0],
            "rot": [0, 270, 0]
          },
          {
            "id": "roof",
            "asset": "roof_complex",
            "pos": [0, 5, 0]
          }
        ]
      }
    }';

    static final facadeWindowData = '
    {
      "id": "facade_window",
      "type": "jda.asset",
      "kind": "sdf_2d",
      "data": {
        "op": "subtract",
        "children": [
          { "id": "base_wall", "kind": "sdf_primitive", "data": { "primitive_type": "rectangle", "size": [8, 5] } },
          { "id": "window_1", "kind": "sdf_primitive", "data": { "primitive_type": "rectangle", "size": [1.5, 2] }, "pos": [-2, 0.5] },
          { "id": "window_2", "kind": "sdf_primitive", "data": { "primitive_type": "rectangle", "size": [1.5, 2] }, "pos": [2, 0.5] }
        ]
      },
      "material": "mat_wall_beige"
    }';

    static final roofComplexData = '
    {
      "id": "roof_complex",
      "type": "jda.asset",
      "kind": "sdf_primitive",
      "data": {
        "primitive_type": "cone",
        "radius": 4,
        "height": 3,
        "material": "mat_roof_dark"
      }
    }';

    static final treeStylizedData = '
    {
      "id": "tree_stylized",
      "type": "jda.asset",
      "kind": "sdf_csg_tree",
      "data": {
        "op": "union",
        "children": [
          { "id": "trunk", "kind": "sdf_primitive", "data": { "primitive_type": "cylinder", "height": 6, "radius": 0.8, "material": "mat_wood_dark" } },
          { "id": "foliage", "kind": "sdf_primitive", "data": { "primitive_type": "sphere", "radius": 3, "material": "mat_leaf_green" }, "pos": [0, 6, 0] }
        ]
      }
    }';

    static final materialsData = '
    {
      "id": "materials_town",
      "type": "jda.asset",
      "kind": "material_list",
      "data": [
        { "id": "mat_grass_green", "color": [0.2, 0.6, 0.2] },
        { "id": "mat_wood_light", "shader": "simple_lit_shader", "parameters": { "baseColor": [0.8, 0.7, 0.5] } },
        { "id": "mat_roof_red", "color": [0.7, 0.2, 0.2] },
        { "id": "mat_leaf_green", "color": [0.1, 0.5, 0.1] },
        { "id": "mat_wall_beige", "color": [0.9, 0.85, 0.7] },
        { "id": "mat_wood_dark", "color": [0.4, 0.2, 0.1] },
        { "id": "mat_roof_dark", "color": [0.3, 0.1, 0.1] }
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
                    // ignore bad file; fallback will cover
                }
            }
        }
        if (outScene != null && outAssets.keys().hasNext()) {
            var mats = outAssets.exists("materials_town") ? outAssets.get("materials_town") : null;
            var shader = outAssets.exists("simple_lit_shader") ? outAssets.get("simple_lit_shader") : null;
            return { scene: outScene, assets: outAssets, materials: mats, shaderSimpleLit: shader };
        }
        #end
        return null;
    }

    static function loadFallback():{ scene:Dynamic, assets:Map<String, Dynamic>, materials:Dynamic, shaderSimpleLit:Dynamic } {
        var m = new Map<String, Dynamic>();
        var g = parse(groundData);
        var b1 = parse(buildingPrimitiveData);
        var b2 = parse(buildingHybridData);
        var fw = parse(facadeWindowData);
        var rc = parse(roofComplexData);
        var tr = parse(treeStylizedData);
        m.set(g.id, g);
        m.set(b1.id, b1);
        m.set(b2.id, b2);
        m.set(fw.id, fw);
        m.set(rc.id, rc);
        m.set(tr.id, tr);
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
        return Json.parse(stripComments(raw));
    }

    static inline function stripComments(raw:String):String {
        var cleaned = new StringBuf();
        for (line in raw.split("\n")) {
            var idx = line.indexOf("//");
            if (idx != -1) line = line.substr(0, idx);
            cleaned.add(line);
            cleaned.add("\n");
        }
        return cleaned.toString();
    }
}
