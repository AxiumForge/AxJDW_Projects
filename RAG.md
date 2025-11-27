# Research and Analysis Register (RAG)

## Entry: Heaps Haxe Solar System Compilation Issues (Nov 27, 2025)

### Problem Description:
During the development of the Haxe Heaps Solar System Simulator (`6_solarsystem`), compilation consistently failed with "field not found" errors for fundamental Heaps API elements.

### Key Errors Encountered:
*   `h3d.scene.LightSystem has no field ambientLight`
*   `h3d.mat.PbrMaterial has no field emissiveColor`
*   `h3d.mat.PbrMaterial has no field emissiveIntensity`
*   `h3d.scene.fwd.PointLight has no field power`
*   `h3d.scene.fwd.PointLight has no field range`
*   `h3d.scene.Mesh has no field rotY`

### Analysis and Actions Taken:
Multiple attempts were made to fix the code (`src/Main.hx`) based on:
1.  Common Heaps API usage patterns.
2.  Inferred structure from general Heaps documentation (latest version).
3.  Explicit type definitions (`typedef`) in `src/Data.hx` to improve type safety.
4.  Direct access and instantiation of API elements (e.g., `new PbrMaterial()`, `new Vector()`).
5.  Refactoring material handling to use `PbrMaterial` consistently.
6.  Correcting light instantiation and attachment to the scene graph.

### Conclusion/Unresolved Status:
The persistence of these core API errors, despite rigorous attempts to align with documented modern Heaps API, strongly suggests a significant **version mismatch** between the intended Heaps API and the Heaps library installed in the user's local environment.

Without knowing the exact Heaps version or having a working example of similar functionality from the user's environment, it is impossible to accurately adapt the code to the available API. Further debugging requires user input on their Heaps setup.