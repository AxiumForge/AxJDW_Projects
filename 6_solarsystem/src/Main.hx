// Main.hx - Simplified version for debugging compilation
import hxd.App;
import h3d.prim.Sphere;
import h3d.mat.PbrMaterial;
import h3d.mat.Material;
import h3d.Vector;
import haxe.ds.StringMap;
import h3d.scene.Mesh;

class Main extends App {

    var simulationTime:Float = 0;
    var planets:Array<{ body: Mesh, orbitData: Data.TOrbitParam }> = [];

    override function init() {
        // Most basic ambient light setting
        s3d.lightSystem.ambientLight.color.set(0.2, 0.2, 0.2); 

        var cam = s3d.camera;
        cam.pos.set(0, 200, 300);
        cam.target.set(0, 0, 0);

        var materials = new StringMap<PbrMaterial>();
        for (matData in (Data.materials:Array<Data.TMaterial>)) {
            var mat = new PbrMaterial();
            var color = matData.parameters.baseColor;
            // Use emissive color as base color for the sun for simplicity
            if (matData.shader == "unlit_emissive") {
                 color = matData.parameters.emissive_color;
            }
            if( color != null )
                mat.color.set(color[0], color[1], color[2], 1.0);

            materials.set(matData.id, mat);
        }

        for (node in (Data.scene.nodes:Array<Data.TSceneNode>)) {
            var bodyData = Data.bodies.get(node.asset_key);
            if (bodyData == null) continue;
            
            var bodyMaterial = materials.get(bodyData.data.material);
            if (bodyMaterial == null) continue;

            var sphere = new Sphere(bodyData.data.radius / 10.0);
            var obj = new Mesh(sphere, bodyMaterial, s3d);
            
            if (node.animation != null) {
                var orbitData = Data.orbits.get(node.animation.animation_key);
                if (orbitData != null)
                    planets.push({ body: obj, orbitData: orbitData });
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
            p.body.x = Math.cos(angle) * distance;
            p.body.z = Math.sin(angle) * distance;
        }
    }

    static function main() {
        new Main();
    }
}
