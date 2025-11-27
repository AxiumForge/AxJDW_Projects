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

    var yaw = Math.PI / 4; // around Y axis
    var pitch = Math.PI / 4; // 45 degrees above plane
    var distance = 55.0;
    var target = new h3d.Vector(0, 3, 0);

    var dragging = false;
    final dragSpeed = 0.002;
    final zoomStep = 2.0;
    final panStep = 15.0;

    override function init() {
        new DirLight(new h3d.Vector(0.6, -1.0, 0.3), s3d);

        assets = Data.assets;
        materials = buildMaterialMap();

        for (node in (cast Data.scene.nodes:Array<Dynamic>)) {
            addNode(node, s3d);
        }

        setupInput();
        updateCamera();
    }

    override function update(dt:Float) {
        var rotSpeed = 0.9 * dt;
        var zoomSpeed = 30 * dt;

        if (Key.isDown(Key.LEFT) || Key.isDown(Key.A)) yaw -= rotSpeed;
        if (Key.isDown(Key.RIGHT) || Key.isDown(Key.D)) yaw += rotSpeed;
        if (Key.isDown(Key.UP) || Key.isDown(Key.E)) pitch = Math.min(1.2, pitch + rotSpeed);
        if (Key.isDown(Key.DOWN) || Key.isDown(Key.Q)) pitch = Math.max(0.05, pitch - rotSpeed);
        if (Key.isDown(Key.W)) distance = Math.max(12, distance - zoomSpeed);
        if (Key.isDown(Key.S)) distance = Math.min(120, distance + zoomSpeed);
        if (Key.isDown(Key.Z)) target.y = Math.max(0, target.y - panStep * dt);
        if (Key.isDown(Key.X)) target.y = Math.min(15, target.y + panStep * dt);

        if (Key.isDown(Key.SHIFT)) {
            var forward = new h3d.Vector(Math.cos(yaw), 0, Math.sin(yaw));
            var right = new h3d.Vector(-forward.z, 0, forward.x);
            if (Key.isDown(Key.W)) {
                target.x += forward.x * panStep * dt;
                target.z += forward.z * panStep * dt;
            }
            if (Key.isDown(Key.S)) {
                target.x -= forward.x * panStep * dt;
                target.z -= forward.z * panStep * dt;
            }
            if (Key.isDown(Key.A)) {
                target.x -= right.x * panStep * dt;
                target.z -= right.z * panStep * dt;
            }
            if (Key.isDown(Key.D)) {
                target.x += right.x * panStep * dt;
                target.z += right.z * panStep * dt;
            }
        }

        updateCamera();
    }

    function setupInput() {
        Window.getInstance().addEventTarget(handleEvent);
    }

    function handleEvent(e:Event) {
        switch (e.kind) {
            case EPush:
                if (e.button == 0) dragging = true;
            case ERelease:
                if (e.button == 0) dragging = false;
            case EMove:
                if (dragging) {
                    yaw += e.relX * dragSpeed;
                    pitch = Math.min(1.2, Math.max(0.1, pitch + e.relY * dragSpeed));
                }
            case EWheel:
                distance = Math.max(12, Math.min(120, distance - e.wheelDelta * zoomStep));
            default:
        }
    }

    function updateCamera() {
        var cam = s3d.camera;
        var cosPitch = Math.cos(pitch);
        var x = target.x + Math.cos(yaw) * distance * cosPitch;
        var z = target.z + Math.sin(yaw) * distance * cosPitch;
        var y = target.y + Math.sin(pitch) * distance + 3;
        cam.pos.set(x, y, z);
        cam.target.set(target.x, target.y, target.z);
        cam.up.set(0, 1, 0);
    }

    function addNode(node:Dynamic, parent:h3d.scene.Object) {
        if (Reflect.hasField(node, "asset") && node.asset != null) {
            var obj = createAssetInstance(node.asset, parent);
            applyTransform(obj, node);
        } else if (Reflect.hasField(node, "nodes") && node.nodes != null) {
            var group = new h3d.scene.Object(parent);
            group.name = node.id;
            applyTransform(group, node);
            for (child in (cast node.nodes:Array<Dynamic>)) {
                addNode(child, group);
            }
        }
    }

    function createAssetInstance(assetId:String, parent:h3d.scene.Object):h3d.scene.Object {
        var asset = assets.get(assetId);
        if (asset == null) {
            return new h3d.scene.Object(parent);
        }
        return buildAsset(asset, parent);
    }

    function buildAsset(asset:Dynamic, parent:h3d.scene.Object):h3d.scene.Object {
        return switch (asset.kind) {
            case "sdf_primitive":
                createPrimitive(asset, parent);
            case "sdf_csg_tree":
                createCsg(asset, parent);
            case "sdf_2d":
                create2dPlaceholder(asset, parent);
            default:
                new h3d.scene.Object(parent);
        }
    }

    function createPrimitive(asset:Dynamic, parent:h3d.scene.Object):h3d.scene.Object {
        var data:Dynamic = asset.data;
        var prim:h3d.prim.Primitive;
        switch (data.primitive_type) {
            case "cylinder":
                prim = new Cylinder(64, 1, 1, true); // smoother silhouette
            case "box":
                prim = new Cube();
            case "pyramid":
                prim = new Cube(); // placeholder for pyramid
            case "sphere":
                prim = new Sphere(1, 64, 64); // higher tessellation for round shapes
            case "cone":
                prim = new Cylinder(64, 1, 1, true); // placeholder for cone, more segments
            default:
                prim = new Cube();
        }

        var matId = Reflect.hasField(data, "material") ? data.material : null;
        var mesh = new Mesh(prim, resolveMaterial(matId), parent);
        if (data.size != null) {
            mesh.scaleX *= data.size[0];
            mesh.scaleY *= data.size[1];
            mesh.scaleZ *= data.size[2];
        } else if (data.radius != null) {
            var r:Float = data.radius;
            mesh.scaleX *= r;
            mesh.scaleZ *= r;
            if (data.height != null) mesh.scaleY *= data.height;
        } else if (data.height != null) {
            mesh.scaleY *= data.height;
        }
        mesh.name = asset.id;
        return mesh;
    }

    function createCsg(asset:Dynamic, parent:h3d.scene.Object):h3d.scene.Object {
        var group = new h3d.scene.Object(parent);
        group.name = asset.id;
        for (child in (cast asset.data.children:Array<Dynamic>)) {
            var childObj:h3d.scene.Object;
            if (Reflect.hasField(child, "asset") && child.asset != null) {
                childObj = createAssetInstance(child.asset, group);
            } else if (child.op == "extrude") {
                childObj = createExtrudedWall(child, group);
            } else if (Reflect.hasField(child, "kind")) {
                childObj = createPrimitive(child, group);
            } else {
                childObj = new h3d.scene.Object(group);
            }
            applyTransform(childObj, child);
        }
        return group;
    }

    function createExtrudedWall(child:Dynamic, parent:h3d.scene.Object):h3d.scene.Object {
        var sourceId:String = child.data.source_2d_sdf;
        var facade = assets.get(sourceId);
        var wallSize = getFacadeSize(facade);
        var depth:Float = (child.data.extrude_depth != null) ? child.data.extrude_depth : 1.0;
        var prim = new Cube(wallSize.x, wallSize.y, depth);
        var matId = Reflect.hasField(facade, "material") ? facade.material : null;
        var mesh = new Mesh(prim, resolveMaterial(matId), parent);
        mesh.name = 'extrude_' + sourceId;
        return mesh;
    }

    function create2dPlaceholder(asset:Dynamic, parent:h3d.scene.Object):h3d.scene.Object {
        var size = getFacadeSize(asset);
        var prim = new Cube(size.x, size.y, 0.2);
        var matId = Reflect.hasField(asset, "material") ? asset.material : null;
        var mesh = new Mesh(prim, resolveMaterial(matId), parent);
        mesh.name = asset.id;
        return mesh;
    }

    function getFacadeSize(asset:Dynamic):{ x:Float, y:Float } {
        var width = 4.0;
        var height = 4.0;
        if (asset != null && asset.data != null && asset.data.children != null) {
            for (child in (cast asset.data.children:Array<Dynamic>)) {
                if (child.kind == "sdf_primitive" && child.data.primitive_type == "rectangle" && child.data.size != null) {
                    width = child.data.size[0];
                    height = child.data.size[1];
                    break;
                }
            }
        }
        return { x: width, y: height };
    }

    function applyTransform(obj:h3d.scene.Object, node:Dynamic) {
        if (Reflect.hasField(node, "pos") && node.pos != null) {
            obj.setPosition(node.pos[0], node.pos[1], node.pos[2]);
        }
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
        if (id != null && materials.exists(id)) {
            return materials.get(id);
        }
        var fallback = new PbrMaterial();
        fallback.color.set(0.7, 0.7, 0.75);
        return fallback;
    }

    function buildMaterialMap():StringMap<Material> {
        var map = new StringMap<Material>();
        for (entry in (cast Data.materials.data:Array<Dynamic>)) {
            var color:Array<Float> = null;
            if (entry.color != null) {
                color = entry.color;
            } else if (entry.parameters != null && entry.parameters.baseColor != null) {
                color = entry.parameters.baseColor;
            }
            var mat = new PbrMaterial();
            if (color != null) {
                mat.color.set(color[0], color[1], color[2]);
            } else {
                mat.color.set(0.6, 0.6, 0.6);
            }
            map.set(entry.id, mat);
        }
        return map;
    }

    static function main() {
        new Main();
    }
}
