// Main.hx - Fixed version using learnings from 1_town/heaps_viewer/src/Main.hx
import hxd.App;
import h3d.prim.Sphere;
import h3d.mat.PbrMaterial;
import h3d.mat.Material;
import h3d.Vector;
import haxe.ds.StringMap;
import h3d.scene.Mesh;
import h3d.scene.fwd.PointLight;
import h3d.scene.DirLight; // Corrected import for DirLight

class Main extends App {

    var simulationTime:Float = 0;
    var planets:Array<{ body: Mesh, orbitData: Data.TOrbitParam }> = [];

    override function init() {
        // Ambient light setup as seen in working example
        s3d.lightSystem.ambientLight.color.set(0.1, 0.1, 0.1); 

        // Camera setup
        var cam = s3d.camera;
        cam.setPosition(0, 200, 300); // Using setPosition
        cam.target.set(0, 0, 0);

        // Directional Light from working example
        new DirLight(new h3d.Vector(0.6, -1.0, 0.3), s3d); // Add a simple directional light

        // --- Create a map for materials for easy lookup ---
        var materials = new StringMap<PbrMaterial>(); // All materials will be PbrMaterial
        for (matData in (Data.materials:Array<Data.TMaterial>)) {
            var mat = new PbrMaterial();

            if (matData.shader == "unlit_emissive") {
                var emissiveColor = matData.parameters.emissive_color;
                if( emissiveColor != null )
                    mat.emissiveColor = new Vector(emissiveColor[0], emissiveColor[1], emissiveColor[2]);
                
                var intensity = matData.parameters.intensity;
                if( intensity != null )
                    mat.emissiveIntensity = intensity;

                mat.color.set(0,0,0,1); // Base color black for purely emissive object
            } else { // standard_lit
                var baseColor = matData.parameters.baseColor;
                if( baseColor != null )
                    mat.color.set(baseColor[0], baseColor[1], baseColor[2], 1.0);
            }
            materials.set(matData.id, mat);
        }

        // --- Process scene nodes ---
        for (node in (Data.scene.nodes:Array<Data.TSceneNode>)) {
            var bodyData = Data.bodies.get(node.asset_key);
            if (bodyData == null) continue;
            
            var bodyMaterial = materials.get(bodyData.data.material);
            if (bodyMaterial == null) continue;

            var sphere = new Sphere(bodyData.data.radius / 10.0);
            var obj = new Mesh(sphere, bodyMaterial, s3d); // Using new Mesh(primitive, material, parent)
            
            if (node.animation != null) {
                var orbitData = Data.orbits.get(node.animation.animation_key);
                if (orbitData != null)
                    planets.push({ body: obj, orbitData: orbitData });

            } else { // It's the sun, add a light source at its position
                var sunLight = new PointLight(obj); // Parent the light to the sun mesh directly
                sunLight.color.set(1, 0.9, 0.6); // Set color (not emissive)
                sunLight.power = 100.0; // Set power as seen in examples (not range/intensity as before)
                sunLight.range = 1000.0; // Set range as seen in examples
                // s3d.addChild(sunLight); // No need, parented already
            }
        }
    }

    override function update(dt:Float) {
        var timeControl = Data.scene.scene_context.time_control;
        var secondsPerDay = timeControl.seconds_per_unit;
        simulationTime += dt / secondsPerDay;

        for (p in planets) {
            var orbit = p.orbitData;
            var angle = (simulationTime / orbit.orbital_period_days) * 2 * Math.PI;
            var distance = orbit.semi_major_axis / 10.0;
            p.body.setPosition(Math.cos(angle) * distance, 0, Math.sin(angle) * distance); // Using setPosition
            p.body.rotY += 0.01; // This should work if other issues are resolved
        }
    }

    static function main() {
        new Main();
    }
}
