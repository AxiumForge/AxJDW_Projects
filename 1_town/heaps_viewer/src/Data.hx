import haxe.Json;

class Data {
    // Raw JDW/JDA blobs (declared first so HL init order is safe)
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

    // Parsed objects (after the raw strings)
    public static final scene:Dynamic = parse(sceneData);
    public static final ground:Dynamic = parse(groundData);
    public static final buildingPrimitive:Dynamic = parse(buildingPrimitiveData);
    public static final buildingHybrid:Dynamic = parse(buildingHybridData);
    public static final facadeWindow:Dynamic = parse(facadeWindowData);
    public static final roofComplex:Dynamic = parse(roofComplexData);
    public static final treeStylized:Dynamic = parse(treeStylizedData);
    public static final materials:Dynamic = parse(materialsData);
    public static final shaderSimpleLit:Dynamic = parse(simpleLitData);

    public static final assets:Array<Dynamic> = [
        ground,
        buildingPrimitive,
        buildingHybrid,
        facadeWindow,
        roofComplex,
        treeStylized
    ];

    public static function assetById():Map<String, Dynamic> {
        var m = new Map<String, Dynamic>();
        for (a in assets) {
            m.set(a.id, a);
        }
        return m;
    }

    static inline function parse(raw:String):Dynamic {
        return Json.parse(stripComments(raw));
    }

    static inline function stripComments(raw:String):String {
        var cleaned = new StringBuf();
        for (line in raw.split("\n")) {
            var idx = line.indexOf("//");
            if (idx != -1) {
                line = line.substr(0, idx);
            }
            cleaned.add(line);
            cleaned.add("\n");
        }
        return cleaned.toString();
    }
}
