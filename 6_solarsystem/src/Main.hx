import hxd.App;
import h3d.prim.Sphere;
import h3d.mat.PbrMaterial;
import h3d.mat.Material; // Use for map type
import h3d.Vector;
import h3d.Vector4;
import hxd.res.Loader;
import haxe.ds.StringMap;
import h3d.scene.Mesh;
import h3d.scene.fwd.PointLight; // Explicit import
// import h3d.scene.AmbientLight; // Not needed with s3d.lightSystem.ambientLight.color.set()

class Main extends App {

    var simulationTime:Float = 0;
    var planets:Array<{ body: h3d.scene.Mesh, orbitData: Data.TOrbitParam }> = [];

    override function init() {
        // Correct way to set ambient light based on Heaps examples
        s3d.lightSystem.ambientLight.color.set(0.1, 0.1, 0.1); 

        var cam = s3d.camera;
        cam.pos.set(0, 200, 300); // Initial camera position
        cam.target.set(0, 0, 0); // Look at the origin

        // --- Create a map for materials for easy lookup ---
        var materials = new StringMap<Material>(); // Use h3d.mat.Material here
        for (matData in (Data.materials:Array<Data.TMaterial>)) { // Explicitly cast to Array
            var mat:PbrMaterial = new PbrMaterial(); // Always use PbrMaterial for consistency

            if (matData.shader == "unlit_emissive") {
                var emissiveColor = matData.parameters.emissive_color;
                if (emissiveColor != null) {
                    mat.emissiveColor = new Vector(emissiveColor[0], emissiveColor[1], emissiveColor[2]); // Set h3d.Vector directly
                }
                var intensity = matData.parameters.intensity;
                if (intensity != null) {
                    mat.emissiveIntensity = intensity; // Use emissiveIntensity field
                }
                mat.color.set(0,0,0,1); // Base color should be black for purely emissive object
            } else { // standard_lit (PBR material)
                var baseColor = matData.parameters.baseColor;
                if (baseColor != null) {
                    mat.color.set(baseColor[0], baseColor[1], baseColor[2], 1.0); // PbrMaterial expects Vector4
                }
            }
            materials.set(matData.id, mat);
        }

        // --- Process scene nodes ---
        for (node in (Data.scene.nodes:Array<Data.TSceneNode>)) { // Explicitly cast to Array
            var bodyData = Data.bodies.get(node.asset_key); // Use StringMap.get()
            if (bodyData == null) {
                trace('Error: Body data not found for asset_key: ${node.asset_key}');
                continue;
            }
            
            var bodyRadius = bodyData.data.radius / 10.0; // Scale down for visibility
            var bodyMaterial = materials.get(bodyData.data.material);
            
            if (bodyMaterial == null) {
                trace('Error: Material not found for: ${bodyData.data.material}');
                continue;
            }

            var sphere = new Sphere(bodyRadius);
            // Correct way to create a renderable Mesh object and add it to the scene
            var obj = new Mesh(sphere, bodyMaterial, s3d); // Parent is s3d directly
            
            if (node.animation != null) {
                var orbitData = Data.orbits.get(node.animation.animation_key); // Use StringMap.get()
                if (orbitData != null) {
                    planets.push({ body: obj, orbitData: orbitData });
                } else {
                    trace('Error: Orbit data not found for animation_key: ${node.animation.animation_key}');
                }
            } else { // It's the sun, add a light source at its position
                var sunLight = new PointLight(new Vector(1.0, 0.9, 0.6), 1.0, 1000.0);
                s3d.addChild(sunLight); // Add light directly to the scene
                sunLight.parent = obj; // Attach light to the sun object (which is a Mesh, subclass of Object)
            }
        }
    }

    override function update(dt:Float) {
        // --- Update simulation time based on scene context ---
        var timeControl = Data.scene.scene_context.time_control;
        var secondsPerDay = timeControl.seconds_per_unit;
        simulationTime += dt / secondsPerDay; // dt is in seconds, so this gives us fraction of a day

        // --- Animate planets ---
        for (p in planets) {
            var orbit = p.orbitData;
            
            // Calculate angle in radians
            var angle = (simulationTime / orbit.orbital_period_days) * 2 * Math.PI;
            
            // NOTE: Simplified circular orbit for this demo. Eccentricity and inclination would require more complex math.
            var distance = orbit.semi_major_axis / 10.0; // Scale down
            p.body.x = Math.cos(angle) * distance;
            p.body.z = Math.sin(angle) * distance;

            // Optional: add a small rotation to the planet itself for visual effect
            p.body.rotY += 0.01;
        }
    }

    static function main() {
        new Main();
    }
}
