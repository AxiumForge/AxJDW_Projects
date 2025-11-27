import hxd.App;
import h3d.scene.Scene;
import h3d.prim.Sphere;
import h3d.mat.PbrMaterial;
import h3d.mat.BaseMaterial;
import hxd.res.Loader;
import haxe.ds.StringMap;

class Main extends App {

    var s3d:Scene;
    var simulationTime:Float = 0;
    var planets:Array<{ body: h3d.scene.Object, orbitData: Dynamic }> = [];

    override function init() {
        s3d = new Scene();
        s3d.lightSystem.ambientLight.set(0.1, 0.1, 0.1);
        var cam = s3d.camera;
        cam.pos.set(0, 200, 300);
        cam.target.set(0, 0, 0);

        // --- Create a map for materials for easy lookup ---
        var materials = new StringMap<BaseMaterial>();
        for (matData in Data.materials) {
            var mat:BaseMaterial;
            if (matData.shader == "unlit_emissive") {
                var m = new h3d.mat.Pass();
                var colorVec = new h3d.Vector(matData.parameters.emissive_color[0], matData.parameters.emissive_color[1], matData.parameters.emissive_color[2]);
                m.getShader().color = colorVec;
                mat = m;
            } else { // standard_lit
                var m = new PbrMaterial();
                var colorVec = new h3d.Vector(matData.parameters.baseColor[0], matData.parameters.baseColor[1], matData.parameters.baseColor[2]);
                m.color = colorVec;
                mat = m;
            }
            materials.set(matData.id, mat);
        }

        // --- Process scene nodes ---
        for (node in Data.scene.nodes) {
            var bodyData = Reflect.field(Data.bodies, node.asset_key);
            var bodyRadius = bodyData.data.radius / 10.0; // Scale down for visibility
            var bodyMaterial = materials.get(bodyData.data.material);
            
            var sphere = new Sphere(bodyRadius);
            var obj = new h3d.scene.Object(sphere, bodyMaterial, s3d);

            if (node.animation != null) {
                var orbitData = Reflect.field(Data.orbits, node.animation.animation_key);
                planets.push({ body: obj, orbitData: orbitData });
            } else { // It's the sun
                s3d.lightSystem.addLight(h3d.scene.fwd.PointLight.fromColor(0xFFFFFF, 1.0, 1000, obj));
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
            var angle = (simulationTime / orbit.orbital_period_days) * 2 * Math.PI;
            
            // NOTE: Simplified circular orbit for this demo. Eccentricity would require more complex math.
            var distance = orbit.semi_major_axis / 10.0; // Scale down
            p.body.x = Math.cos(angle) * distance;
            p.body.z = Math.sin(angle) * distance;
        }
    }

    static function main() {
        new Main();
    }
}
