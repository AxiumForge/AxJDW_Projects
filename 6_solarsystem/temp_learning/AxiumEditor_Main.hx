import camera.CameraState;
import camera.CameraStateTools;
import camera.CameraController;
import ui.AssetSelector;
import ui.Inspector;
import ui.InspectorModel;
import ui.SceneGraph;
import loader.Jda3dLoader;
import loader.JdwLoader;
import loader.RuntimeShaderCompiler;

// Import generated shaders from CLI compilation
import SphereBasicShader;
import RoundedBoxShader;
import PillarRepeatShader;

class Main extends hxd.App {
    static var cliAssetPath:String = null;  // Asset path from CLI argument
    static var screenshotPath:String = null;  // Screenshot path from CLI argument
    static var scriptPath:String = null;  // Script path from CLI argument

    var currentShader:Dynamic;  // Can be any of the 3 shaders - using Dynamic for direct property access
    var bitmap:h2d.Bitmap;
    var interactive:h2d.Interactive;
    var assetSelector:AssetSelector;
    var inspector:Inspector;
    var currentAssetPath:String;

    // Generated shaders (compiled from JDA assets via CLI)
    var sphereShader:SphereBasicShader;
    var roundedBoxShader:RoundedBoxShader;
    var pillarRepeatShader:PillarRepeatShader;

    // Camera system
    var cameraController:CameraController;

    // Input state
    var isDragging:Bool = false;
    var isShiftPressed:Bool = false;
    var lastMouseX:Float = 0;
    var lastMouseY:Float = 0;

    // Screenshot mode
    var frameCounter:Int = 0;
    var screenshotTaken:Bool = false;

    // Script runner
    var scriptRunner:ScriptRunner = null;

    override function init() {
        // Initialize all 3 generated shaders (from CLI compilation)
        sphereShader = new SphereBasicShader();
        roundedBoxShader = new RoundedBoxShader();
        pillarRepeatShader = new PillarRepeatShader();

        // Start with sphere
        currentShader = sphereShader;

        // Create fullscreen bitmap with current shader
        bitmap = new h2d.Bitmap(h2d.Tile.fromColor(0x000000, engine.width, engine.height));
        bitmap.addShader(currentShader);
        s2d.addChildAt(bitmap, 0);  // Add at the bottom

        // Initialize camera controller with starting orbit state
        var initialState = CameraStateTools.createOrbit(
            new h3d.Vector(0, 0, 0),  // Target at origin
            5.0,                       // Distance from target
            45.0,                      // Yaw (45° around Y axis)
            -30.0                      // Pitch (looking down 30°)
        );
        cameraController = new CameraController(initialState);

        // Setup h3d camera from initial state
        updateCameraFromState();

        // Initialize shader camera
        updateShaderCamera(currentShader);

        // Setup fullscreen interactive for input (behind UI elements)
        interactive = new h2d.Interactive(engine.width, engine.height);
        s2d.addChildAt(interactive, 1);  // Add after bitmap but before UI
        interactive.enableRightButton = true;  // Enable middle mouse button

        interactive.onPush = function(e:hxd.Event) {
            if (e.button == 0 || e.button == 1) {  // Left or Middle mouse button
                isDragging = true;
                lastMouseX = e.relX;
                lastMouseY = e.relY;
            }
        };

        interactive.onRelease = function(e:hxd.Event) {
            if (e.button == 0 || e.button == 1) {  // LMB or MMB release
                isDragging = false;
            }
        };

        interactive.onMove = function(e:hxd.Event) {
            if (isDragging) {
                var deltaX = e.relX - lastMouseX;
                var deltaY = e.relY - lastMouseY;

                if (isShiftPressed) {
                    // Shift+MMB: Pan
                    cameraController.pan(deltaX, -deltaY);  // Invert Y for natural feel
                } else {
                    // MMB: Rotate
                    cameraController.rotate(deltaX, deltaY);
                }

                lastMouseX = e.relX;
                lastMouseY = e.relY;

                updateCameraFromState();
            }
        };

        interactive.onWheel = function(e:hxd.Event) {
            // Mouse wheel: Zoom
            cameraController.zoom(e.wheelDelta);
            updateCameraFromState();
        };

        interactive.onKeyDown = function(e:hxd.Event) {
            if (e.keyCode == hxd.Key.SHIFT) {
                isShiftPressed = true;
            }
        };

        interactive.onKeyUp = function(e:hxd.Event) {
            if (e.keyCode == hxd.Key.SHIFT) {
                isShiftPressed = false;
            }
        };

        // ===== VP6: Asset Selector UI =====
        assetSelector = new AssetSelector(s2d, function(assetName:String) {
            switchShader(assetName);
        });
        assetSelector.setPos(10, 10);
        // ===== End VP6 =====

        // ===== VP6 Phase 6.2: Inspector Panel =====
        inspector = new Inspector(s2d, engine.height);
        inspector.positionRight(engine.width);

        // Load initial asset data for inspector
        // Use CLI argument if provided, otherwise default to sphere
        if (cliAssetPath != null) {
            trace('CLI: Loading asset from command line: $cliAssetPath');
            currentAssetPath = cliAssetPath;
            // Also switch to that shader
            switchShader(cliAssetPath);
        } else {
            currentAssetPath = "assets/jda3d/jda.shape.sphere_basic.json";
            // Auto-position camera for initial asset
            autoCameraPosition(currentAssetPath);
        }
        updateInspector(currentAssetPath);
        // ===== End VP6.2 =====

        // ===== Script Runner =====
        if (scriptPath != null) {
            trace('Script mode: Loading script from: $scriptPath');
            scriptRunner = new ScriptRunner(this);
            scriptRunner.loadScriptFile(scriptPath);
            scriptRunner.start();
        }
        // ===== End Script Runner =====
    }

    /**
     * Estimate bounding sphere radius from SDF tree
     * Returns a conservative radius estimate for camera auto-positioning
     */
    function estimateBoundingRadius(sdfTree:loader.Jda3dTypes.SdfNode):Float {
        return switch(sdfTree) {
            case Primitive(dim, shape, params):
                switch(shape) {
                    case Sphere:
                        // Sphere: radius from params (default 1.0)
                        if (params.exists("radius")) params.get("radius") else 1.0;

                    case Box:
                        // Box: diagonal from center to corner
                        if (params.exists("size")) {
                            var sizeArray:Array<Dynamic> = cast params.get("size");
                            var sx:Float = sizeArray[0];
                            var sy:Float = sizeArray[1];
                            var sz:Float = sizeArray[2];
                            // Half-size diagonal
                            Math.sqrt(sx*sx + sy*sy + sz*sz) * 0.5;
                        } else {
                            1.732;  // Default cube size=2, radius=sqrt(3)
                        }

                    case Torus:
                        // Torus: major_radius + minor_radius
                        var major = if (params.exists("major_radius")) params.get("major_radius") else 1.0;
                        var minor = if (params.exists("minor_radius")) params.get("minor_radius") else 0.3;
                        major + minor;

                    case Cylinder:
                        // Cylinder: max of radius and half height
                        var radius = if (params.exists("radius")) params.get("radius") else 1.0;
                        var height = if (params.exists("height")) params.get("height") else 2.0;
                        Math.max(radius, height * 0.5);

                    case Capsule:
                        // Capsule: radius + half height
                        var radius = if (params.exists("radius")) params.get("radius") else 1.0;
                        var height = if (params.exists("height")) params.get("height") else 2.0;
                        radius + height * 0.5;

                    case Plane:
                        // Plane: infinite, use default camera distance
                        3.0;
                }

            case Operation(op, params, children):
                // CSG: conservative max of children + 20% margin
                var maxRadius = 0.0;
                for (child in children) {
                    var childRadius = estimateBoundingRadius(child);
                    if (childRadius > maxRadius) maxRadius = childRadius;
                }
                maxRadius * 1.2;

            case Modifier(modType, modParams, child):
                // Modifiers: child bounding * modifier factor
                var childRadius = estimateBoundingRadius(child);
                switch(modType) {
                    case Repeat:
                        // Repeat: use base child size (don't multiply by infinite repetition)
                        childRadius;
                    default:
                        // Other modifiers: conservative estimate
                        childRadius * 1.5;
                }

            case Reference(assetId, params):
                // Reference: can't estimate without loading, use default
                2.0;
        };
    }

    /**
     * Auto-position camera to frame the loaded asset
     */
    function autoCameraPosition(assetPath:String) {
        try {
            var doc = Jda3dLoader.loadFromFile(assetPath);
            var boundingRadius = estimateBoundingRadius(doc.sdfTree);

            // Calculate optimal camera distance (2.5x bounding radius for good framing)
            var distance = boundingRadius * 2.5;

            // Clamp to reasonable values
            if (distance < 2.0) distance = 2.0;
            if (distance > 20.0) distance = 20.0;

            // Create new camera state with auto-positioned camera
            var newState = CameraStateTools.createOrbit(
                new h3d.Vector(0, 0, 0),  // Target at origin (assets are centered)
                distance,
                45.0,   // Yaw 45°
                -30.0   // Pitch -30° (looking down)
            );

            cameraController = new CameraController(newState);
            updateCameraFromState();

            trace('Auto-positioned camera: boundingRadius=$boundingRadius, distance=$distance');
        } catch (e:Dynamic) {
            trace('Warning: Could not auto-position camera: $e');
        }
    }

    /**
     * Switch shader at runtime (no recompile needed!)
     */
    function switchShader(assetNameOrPath:String) {
        // Remove old shader
        bitmap.remove();

        // Check if input is a file path or display name
        var assetPath:String;
        if (assetNameOrPath.indexOf("/") >= 0) {
            // Input is a full path (from browse button)
            // Compile shader at runtime!
            assetPath = assetNameOrPath;
            trace('Loading browsed file: $assetPath');

            try {
                currentShader = RuntimeShaderCompiler.compileFromJda(assetPath);
                trace('Successfully compiled runtime shader!');
            } catch (e:Dynamic) {
                trace('Runtime compilation failed: $e');
                trace('Falling back to sphereShader');
                currentShader = sphereShader;
            }
        } else {
            // Input is a display name (from asset list) - map to pre-compiled shader
            currentShader = switch(assetNameOrPath) {
                case "Sphere":
                    assetPath = "assets/jda3d/jda.shape.sphere_basic.json";
                    sphereShader;
                case "Rounded Box":
                    assetPath = "assets/jda3d/jda.shape.rounded_box.json";
                    roundedBoxShader;
                case "Pillar Repeat":
                    assetPath = "assets/jda3d/jda.shape.pillar_repeat.json";
                    pillarRepeatShader;
                default:
                    assetPath = "assets/jda3d/jda.shape.sphere_basic.json";
                    sphereShader;
            };
        }

        // Create new bitmap with new shader at index 0 (bottom of z-order)
        bitmap = new h2d.Bitmap(h2d.Tile.fromColor(0x000000, engine.width, engine.height));
        bitmap.addShader(currentShader);
        s2d.addChildAt(bitmap, 0);  // Add at the back so UI stays on top

        // Auto-position camera to frame the asset
        autoCameraPosition(assetPath);

        // Update camera uniforms for new shader
        updateShaderCamera(currentShader);

        // Update inspector with new asset data
        currentAssetPath = assetPath;
        updateInspector(currentAssetPath);
    }

    /**
     * Update inspector panel with asset data from JDA file
     */
    function updateInspector(assetPath:String) {
        try {
            var doc = Jda3dLoader.loadFromFile(assetPath);
            var data = InspectorModel.fromJdaDocument(doc);
            inspector.updateData(data);
        } catch (e:Dynamic) {
            trace('Warning: Could not load asset for inspector: $e');
        }
    }

    /**
     * Update h3d.Camera position and target from CameraState
     */
    function updateCameraFromState() {
        var state = cameraController.getState();
        var target = CameraStateTools.getTarget(state);
        var pos = CameraStateTools.computePosition(state);

        s3d.camera.pos.set(pos.x, pos.y, pos.z);
        s3d.camera.target.set(target.x, target.y, target.z);
    }

    /**
     * Update shader camera uniforms (works for all shader types)
     */
    function updateShaderCamera(shader:Dynamic) {
        // HXSL shaders require type-specific casting to access @param fields
        if (Std.isOfType(shader, SphereBasicShader)) {
            var s = cast(shader, SphereBasicShader);
            s.cameraPos = s3d.camera.pos;
            s.cameraTarget = s3d.camera.target;
            s.aspectRatio = engine.width / engine.height;
        } else if (Std.isOfType(shader, RoundedBoxShader)) {
            var s = cast(shader, RoundedBoxShader);
            s.cameraPos = s3d.camera.pos;
            s.cameraTarget = s3d.camera.target;
            s.aspectRatio = engine.width / engine.height;
        } else if (Std.isOfType(shader, PillarRepeatShader)) {
            var s = cast(shader, PillarRepeatShader);
            s.cameraPos = s3d.camera.pos;
            s.cameraTarget = s3d.camera.target;
            s.aspectRatio = engine.width / engine.height;
        } else {
            // Runtime compiled shaders (DynamicShader) - use setVariable method
            // DynamicShader stores @param fields internally and exposes them via setVariable/getVariable
            try {
                var dynShader = cast(shader, hxsl.DynamicShader);
                dynShader.setVariable("cameraPos", s3d.camera.pos);
                dynShader.setVariable("cameraTarget", s3d.camera.target);
                dynShader.setVariable("cameraUp", new h3d.Vector(0, -1, 0));
                dynShader.setVariable("aspectRatio", engine.width / engine.height);
                dynShader.setVariable("fov", 1.0);  // ~60 degrees
            } catch (e:Dynamic) {
                trace('Warning: Could not update shader camera parameters: $e');
            }
        }
    }

    override function update(dt:Float) {
        // Update current shader parameters each frame
        updateShaderCamera(currentShader);

        // Update script runner
        if (scriptRunner != null) {
            scriptRunner.update(dt);
        }

        // Screenshot mode: capture after a few frames (rendering stabilized)
        if (screenshotPath != null && !screenshotTaken) {
            frameCounter++;
            if (frameCounter >= 3) {  // Wait 3 frames for rendering to stabilize
                takeScreenshot(screenshotPath);
                screenshotTaken = true;
                // Exit after screenshot
                haxe.Timer.delay(function() {
                    trace('Screenshot complete, exiting...');
                    Sys.exit(0);
                }, 100);  // Small delay to ensure file is written
            }
        }
    }

    /**
     * Capture screenshot and save to file
     */
    function takeScreenshot(path:String) {
        try {
            // Ensure directory exists
            var dir = haxe.io.Path.directory(path);
            if (dir != "" && !sys.FileSystem.exists(dir)) {
                sys.FileSystem.createDirectory(dir);
            }

            // Create a render target texture
            var renderTexture = new h3d.mat.Texture(engine.width, engine.height, [Target]);

            // Render scene to texture
            engine.pushTarget(renderTexture);
            engine.clear(engine.backgroundColor);
            s2d.render(engine);  // Render 2D scene (includes our fullscreen bitmap with shader)
            engine.popTarget();

            // Capture pixels from the render texture
            var pixels = renderTexture.capturePixels();

            // Save as PNG
            var png = pixels.toPNG();
            sys.io.File.saveBytes(path, png);

            // Clean up
            renderTexture.dispose();

            trace('Screenshot saved: $path (${pixels.width}x${pixels.height})');
        } catch (e:Dynamic) {
            trace('Screenshot error: $e');
        }
    }

    static function main() {
        // Parse CLI arguments
        var args = Sys.args();
        var i = 0;
        while (i < args.length) {
            var arg = args[i];

            if (arg == "--screenshot" && i + 1 < args.length) {
                screenshotPath = args[i + 1];
                trace('CLI: Screenshot mode - will save to: $screenshotPath');
                i += 2;
            } else if (arg == "--script" && i + 1 < args.length) {
                scriptPath = args[i + 1];
                trace('CLI: Script mode - will run script: $scriptPath');
                i += 2;
            } else {
                // First non-flag argument is asset path
                if (cliAssetPath == null) {
                    cliAssetPath = arg;
                    trace('CLI: Will load asset from: $cliAssetPath');
                }
                i++;
            }
        }

        new Main();
    }
}
