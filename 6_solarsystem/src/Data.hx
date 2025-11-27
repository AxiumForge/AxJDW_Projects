import haxe.Json;
import haxe.ds.StringMap; // Added this import

// --- JDA/JDW Type Definitions for better type safety ---

typedef TSceneNode = {
    var id:String;
    var asset_lib:String;
    var asset_key:String;
    @:optional var animation:TAnimationRef;
    @:optional var pos:Array<Float>;
    @:optional var scale:Float;
}

typedef TScene = {
    var id:String;
    var type:String;
    var scene_context:TSceneContext;
    var nodes:Array<TSceneNode>;
}

typedef TSceneContext = {
    var time_control:TTimeControl;
}

typedef TTimeControl = {
    var time_unit:String;
    var seconds_per_unit:Float;
}

typedef TMaterialParam = {
    @:optional var baseColor:Array<Float>;
    @:optional var emissive_color:Array<Float>;
    @:optional var intensity:Float;
}

typedef TMaterial = {
    var id:String;
    var shader:String;
    var parameters:TMaterialParam;
}

typedef TBodyData = {
    var kind:String;
    var data:TBodyPrimitiveData;
}

typedef TBodyPrimitiveData = {
    var primitive_type:String;
    var radius:Float;
    var material:String;
}

typedef TAnimationRef = {
    var source_lib:String;
    var animation_key:String;
    @:optional var autoplay:Bool;
}

typedef TOrbitParam = {
    var kind:String;
    var orbital_period_days:Float;
    var semi_major_axis:Float;
    var eccentricity:Float;
    var inclination:Float;
    var initial_angle_degrees:Float;
}


class Data {
    public static var scene:TScene = Json.parse(sceneData);
    public static var bodies:StringMap<TBodyData> = Json.parse(celestialBodiesData).data;
    public static var materials:Array<TMaterial> = Json.parse(materialsData).data;
    public static var orbits:StringMap<TOrbitParam> = Json.parse(orbitalAnimationsData).data;

    static final sceneData = '
    {
      "id": "solar_system_scene",
      "type": "jdw.scene",
      "scene_context": {
        "time_control": {
          "time_unit": "day",
          "seconds_per_unit": 60 
        }
      },
      "nodes": [
        { "id": "sun", "asset_lib": "celestial_body_models", "asset_key": "sun_model" },
        { "id": "mercury", "asset_lib": "celestial_body_models", "asset_key": "mercury_model", "animation": { "source_lib": "solar_system_orbits", "animation_key": "mercury_orbit", "autoplay": true } },
        { "id": "venus", "asset_lib": "celestial_body_models", "asset_key": "venus_model", "animation": { "source_lib": "solar_system_orbits", "animation_key": "venus_orbit", "autoplay": true } },
        { "id": "earth", "asset_lib": "celestial_body_models", "asset_key": "earth_model", "animation": { "source_lib": "solar_system_orbits", "animation_key": "earth_orbit", "autoplay": true } },
        { "id": "mars", "asset_lib": "celestial_body_models", "asset_key": "mars_model", "animation": { "source_lib": "solar_system_orbits", "animation_key": "mars_orbit", "autoplay": true } }
      ]
    }';

    static final celestialBodiesData = '
    {
      "id": "celestial_body_models", "type": "jda.asset", "kind": "sdf_library",
      "data": {
        "sun_model": { "kind": "sdf_primitive", "data": { "primitive_type": "sphere", "radius": 6.96, "material": "mat_sun" } },
        "mercury_model": { "kind": "sdf_primitive", "data": { "primitive_type": "sphere", "radius": 0.24, "material": "mat_mercury" } },
        "venus_model": { "kind": "sdf_primitive", "data": { "primitive_type": "sphere", "radius": 0.6, "material": "mat_venus" } },
        "earth_model": { "kind": "sdf_primitive", "data": { "primitive_type": "sphere", "radius": 0.63, "material": "mat_earth" } },
        "mars_model": { "kind": "sdf_primitive", "data": { "primitive_type": "sphere", "radius": 0.34, "material": "mat_mars" } }
      }
    }';

    static final materialsData = '
    {
      "id": "materials_solarsystem", "type": "jda.asset", "kind": "material_list",
      "data": [
        { "id": "mat_sun", "shader": "unlit_emissive", "parameters": { "emissive_color": [1.0, 0.9, 0.6], "intensity": 2.0 } },
        { "id": "mat_mercury", "shader": "standard_lit", "parameters": { "baseColor": [0.5, 0.5, 0.5] } },
        { "id": "mat_venus", "shader": "standard_lit", "parameters": { "baseColor": [0.8, 0.7, 0.5] } },
        { "id": "mat_earth", "shader": "standard_lit", "parameters": { "baseColor": [0.2, 0.3, 0.8] } },
        { "id": "mat_mars", "shader": "standard_lit", "parameters": { "baseColor": [0.7, 0.3, 0.1] } }
      ]
    }';

    static final orbitalAnimationsData = '
    {
      "id": "solar_system_orbits", "type": "jda.asset", "kind": "animation_library",
      "data": {
        "mercury_orbit": { "kind": "animation_parametric_orbit", "orbital_period_days": 88, "semi_major_axis": 57.9, "eccentricity": 0.205, "inclination": 7.0, "initial_angle_degrees": 45 },
        "venus_orbit": { "kind": "animation_parametric_orbit", "orbital_period_days": 225, "semi_major_axis": 108.2, "eccentricity": 0.007, "inclination": 3.4, "initial_angle_degrees": 120 },
        "earth_orbit": { "kind": "animation_parametric_orbit", "orbital_period_days": 365, "semi_major_axis": 149.6, "eccentricity": 0.017, "inclination": 0.0, "initial_angle_degrees": 0 },
        "mars_orbit": { "kind": "animation_parametric_orbit", "orbital_period_days": 687, "semi_major_axis": 227.9, "eccentricity": 0.094, "inclination": 1.85, "initial_angle_degrees": 210 }
      }
    }';
}
