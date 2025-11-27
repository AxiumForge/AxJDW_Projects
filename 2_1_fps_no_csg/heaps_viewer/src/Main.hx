import h3d.mat.PbrMaterial;
import h3d.mat.Material;
import h3d.prim.Cube;
import h3d.prim.Cylinder;
import h3d.prim.Sphere;
import h3d.scene.Mesh;
import h3d.scene.fwd.DirLight;
import hxd.App;
import hxd.Key;
import hxd.Event;
import hxd.Window;
import haxe.ds.StringMap;

class Main extends App {
    var materials:StringMap<Material>;
    var assets:Map<String, Dynamic>;

    var yaw = Math.PI / 4;
    var pitch = 0.1;
    var distance = 70.0;
    var target = new h3d.Vector(0, 3, 0);
    var mode = "orbit"; // orbit | fps
    var fpsPos = new h3d.Vector(-22, 2, -22);

    var dragging = false;
    final dragSpeed = 0.002;
    final zoomStep = 2.0;
    final panStep = 15.0;
    final moveSpeed = 25.0;

    override function init() {
        new DirLight(new h3d.Vector(0.6, -1.0, 0.3), s3d);
        var fill = new DirLight(new h3d.Vector(-0.4, -0.6, -0.2), s3d);
        fill.color.set(0.6, 0.65, 0.7);

        assets = Data.assets;
        materials = buildMaterialMap();

        for (node in (cast Data.scene.nodes:Array<Dynamic>)) addNode(node, s3d);

        setupInput();
        updateOrbitCamera();
    }

    override function update(dt:Float) {
        var rotSpeed = 0.9 * dt;
        var zoomSpeed = 30 * dt;

        if (Key.isPressed(Key.F)) mode = mode == "orbit" ? "fps" : "orbit";

        if (mode == "orbit") updateOrbit(dt, rotSpeed, zoomSpeed);
        else updateFps(dt, rotSpeed);
    }

    function setupInput() {
        Window.getInstance().addEventTarget(handleEvent);
    }

    function handleEvent(e:Event) {
        switch (e.kind) {
            case EPush: if (e.button == 0) dragging = true;
            case ERelease: if (e.button == 0) dragging = false;
            case EMove:
                if (dragging) {
                    yaw += e.relX * dragSpeed;
                    pitch = Math.min(1.2, Math.max(-0.2, pitch + e.relY * dragSpeed));
                }
            case EWheel:
                distance = Math.max(12, Math.min(160, distance - e.wheelDelta * zoomStep));
            default:
        }
    }

    function updateOrbit(dt:Float, rotSpeed:Float, zoomSpeed:Float) {
        if (Key.isDown(Key.LEFT) || Key.isDown(Key.A)) yaw -= rotSpeed;
        if (Key.isDown(Key.RIGHT) || Key.isDown(Key.D)) yaw += rotSpeed;
        if (Key.isDown(Key.UP) || Key.isDown(Key.E)) pitch = Math.min(1.2, pitch + rotSpeed);
        if (Key.isDown(Key.DOWN) || Key.isDown(Key.Q)) pitch = Math.max(-0.2, pitch - rotSpeed);
        if (Key.isDown(Key.W)) distance = Math.max(12, distance - zoomSpeed);
        if (Key.isDown(Key.S)) distance = Math.min(160, distance + zoomSpeed);
        if (Key.isDown(Key.Z)) target.y = Math.max(0, target.y - panStep * dt);
        if (Key.isDown(Key.X)) target.y = Math.min(20, target.y + panStep * dt);

        if (Key.isDown(Key.SHIFT)) {
            var forward = new h3d.Vector(Math.cos(yaw), 0, Math.sin(yaw));
            var right = new h3d.Vector(-forward.z, 0, forward.x);
            if (Key.isDown(Key.W)) { target.x += forward.x * panStep * dt; target.z += forward.z * panStep * dt; }
            if (Key.isDown(Key.S)) { target.x -= forward.x * panStep * dt; target.z -= forward.z * panStep * dt; }
            if (Key.isDown(Key.A)) { target.x -= right.x * panStep * dt; target.z -= right.z * panStep * dt; }
            if (Key.isDown(Key.D)) { target.x += right.x * panStep * dt; target.z += right.z * panStep * dt; }
        }
        updateOrbitCamera();
    }

    function updateFps(dt:Float, rotSpeed:Float) {
        if (Key.isDown(Key.LEFT) || Key.isDown(Key.A)) yaw -= rotSpeed;
        if (Key.isDown(Key.RIGHT) || Key.isDown(Key.D)) yaw += rotSpeed;
        if (Key.isDown(Key.UP) || Key.isDown(Key.E)) pitch = Math.min(0.6, pitch + rotSpeed);
        if (Key.isDown(Key.DOWN) || Key.isDown(Key.Q)) pitch = Math.max(-0.2, pitch - rotSpeed);

        var forward = new h3d.Vector(Math.cos(yaw), 0, Math.sin(yaw));
        var right = new h3d.Vector(-forward.z, 0, forward.x);
        var move = new h3d.Vector();
        if (Key.isDown(Key.W)) { move.x += forward.x; move.z += forward.z; }
        if (Key.isDown(Key.S)) { move.x -= forward.x; move.z -= forward.z; }
        if (Key.isDown(Key.A)) { move.x -= right.x; move.z -= right.z; }
        if (Key.isDown(Key.D)) { move.x += right.x; move.z += right.z; }
        if (Key.isDown(Key.Z)) move.y -= 1;
        if (Key.isDown(Key.X)) move.y += 1;

        if (move.lengthSq() > 0) {
            move.normalize();
            fpsPos.x += move.x * moveSpeed * dt;
            fpsPos.y = Math.max(1.0, fpsPos.y + move.y * moveSpeed * dt);
            fpsPos.z += move.z * moveSpeed * dt;
        }
        updateFpsCamera();
    }

    function updateOrbitCamera() {
        var cam = s3d.camera;
        var cosPitch = Math.cos(pitch);
        var x = target.x + Math.cos(yaw) * distance * cosPitch;
        var z = target.z + Math.sin(yaw) * distance * cosPitch;
        var y = target.y + Math.sin(pitch) * distance + 3;
        cam.pos.set(x, y, z);
        cam.target.set(target.x, target.y, target.z);
        cam.up.set(0, 1, 0);
    }

    function updateFpsCamera() {
        var cam = s3d.camera;
        var forward = new h3d.Vector(Math.cos(yaw), 0, Math.sin(yaw));
        var look = new h3d.Vector(forward.x, Math.sin(pitch), forward.z);
        var dir = look.normalized();
        cam.pos.set(fpsPos.x, fpsPos.y, fpsPos.z);
        cam.target.set(fpsPos.x + dir.x, fpsPos.y + dir.y, fpsPos.z + dir.z);
        cam.up.set(0, 1, 0);
    }

    function addNode(node:Dynamic, parent:h3d.scene.Object) {
        if (Reflect.hasField(node, "asset") && node.asset != null) {
            createLibraryInstance(node.asset, parent, node);
        } else if (Reflect.hasField(node, "nodes") && node.nodes != null) {
            var group = new h3d.scene.Object(parent);
            group.name = node.id;
            applyTransform(group, node);
            for (child in (cast node.nodes:Array<Dynamic>)) addNode(child, group);
        }
    }

    function createLibraryInstance(assetId:String, parent:h3d.scene.Object, node:Dynamic) {
        var lib = assets.get("fps_arena_geometry_no_csg");
        if (lib == null || lib.kind != "sdf_library") return;
        var entry = Reflect.field(lib.data, assetId);
        if (entry == null) return;
        var obj = buildEntry(entry, parent);
        if (obj != null) applyTransform(obj, node);
    }

    function buildEntry(entry:Dynamic, parent:h3d.scene.Object):h3d.scene.Object {
        return switch (entry.kind) {
            case "sdf_primitive": createPrimitive(entry, parent);
            case "sdf_group": createGroup(entry, parent);
            default: new h3d.scene.Object(parent);
        }
    }

    function createGroup(entry:Dynamic, parent:h3d.scene.Object):h3d.scene.Object {
        var g = new h3d.scene.Object(parent);
        g.name = entry.id != null ? entry.id : "group";
        for (child in (cast entry.children:Array<Dynamic>)) {
            var obj = buildEntry(child, g);
            if (obj != null) applyTransform(obj, child);
        }
        return g;
    }

    function createPrimitive(entry:Dynamic, parent:h3d.scene.Object):h3d.scene.Object {
        var data:Dynamic = entry.data;
        var prim:h3d.prim.Primitive;
        switch (data.primitive_type) {
            case "cylinder":
                var radius = data.radius != null ? data.radius : 1.0;
                var height = data.height != null ? data.height : 1.0;
                prim = new Cylinder(64, height, radius, true);
            case "box":
                var sx = (data.size != null && data.size.length > 0) ? data.size[0] : 1.0;
                var sy = (data.size != null && data.size.length > 1) ? data.size[1] : 1.0;
                var sz = (data.size != null && data.size.length > 2) ? data.size[2] : 1.0;
                prim = new Cube(sx, sy, sz);
            case "sphere":
                var r = data.radius != null ? data.radius : 1.0;
                prim = new Sphere(r, 48, 48);
            default:
                prim = new Cube(1, 1, 1);
        }
        var matId = Reflect.hasField(data, "material") ? data.material : null;
        var mesh = new Mesh(prim, resolveMaterial(matId), parent);
        mesh.name = entry.id != null ? entry.id : "prim";
        return mesh;
    }

    function applyTransform(obj:h3d.scene.Object, node:Dynamic) {
        if (Reflect.hasField(node, "pos") && node.pos != null) obj.setPosition(node.pos[0], node.pos[1], node.pos[2]);
        if (Reflect.hasField(node, "rot") && node.rot != null) {
            var rx = node.rot[0] * Math.PI / 180.0;
            var ry = node.rot[1] * Math.PI / 180.0;
            var rz = node.rot[2] * Math.PI / 180.0;
            obj.setRotation(rx, ry, rz);
        }
        if (Reflect.hasField(node, "scale") && node.scale != null) {
            if (Std.isOfType(node.scale, Array)) {
                var arr:Array<Float> = node.scale;
                obj.scaleX = arr[0];
                obj.scaleY = arr[1];
                obj.scaleZ = arr[2];
            } else {
                obj.setScale(node.scale);
            }
        }
    }

    function resolveMaterial(id:String):Material {
        if (id != null && materials.exists(id)) return materials.get(id);
        var fallback = new PbrMaterial();
        fallback.color.set(0.6, 0.65, 0.7);
        return fallback;
    }

    function buildMaterialMap():StringMap<Material> {
        var map = new StringMap<Material>();
        for (entry in (cast Data.materials.data:Array<Dynamic>)) {
            var color:Array<Float> = null;
            if (entry.color != null) color = entry.color;
            else if (entry.parameters != null && entry.parameters.baseColor != null) color = entry.parameters.baseColor;
            var mat = new PbrMaterial();
            if (color != null) mat.color.set(color[0], color[1], color[2]);
            map.set(entry.id, mat);
        }
        return map;
    }

    static function main() {
        new Main();
    }
}
