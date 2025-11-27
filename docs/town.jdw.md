# JDW Town - Proof of Concept

This document describes the structure of a simple town scene, `town.jdw`, designed as a Proof of Concept (PoC) for the JDW/JDA data standard. The aesthetic goal is a stylized world made of "wooden toy blocks" with simple, solid colors, built using Signed Distance Fields (SDF).

The scene consists of a circular base platform, several types of buildings, and stylized trees.

## Scene Structure (`town.jdw`)

The main scene file, `town.jdw`, defines the world's node hierarchy. It references various JDA assets to construct the scene.

```json
// Example structure for town.jdw
{
  "id": "town_scene",
  "type": "jdw.scene",
  "nodes": [
    {
      "id": "ground_disk",
      "asset": "jda_ground_disk", // A large, flat cylinder for the town base
      "pos": [0, 0, 0]
    },
    {
      "id": "buildings",
      "nodes": [
        // Primitive-based building
        { "id": "house_a", "asset": "jda_building_primitive", "pos": [-5, 0, -5] },
        // Hybrid building using 2D and 3D SDFs
        { "id": "house_b", "asset": "jda_building_hybrid", "pos": [5, 0, -2], "rot": [0, 45, 0] }
      ]
    },
    {
      "id": "nature",
      "nodes": [
        { "id": "tree_1", "asset": "jda_tree_stylized", "pos": [8, 0, 8] },
        { "id": "tree_2", "asset": "jda_tree_stylized", "pos": [-10, 0, 4], "scale": 1.2 }
      ]
    }
  ]
}
```

---

## Asset Definitions (JDA Files)

The visual elements of the town are defined in separate JDA files.

### 1. Ground (`ground.jda`)

A simple 3D primitive for the ground plane.

*   **File:** `ground.jda`
*   **Kind:** `sdf_primitive`
*   **Description:** A large, flat cylinder acting as the base for the town.
*   **Data:**
    *   Primitive Type: `cylinder`
    *   Dimensions: `height: 0.2`, `radius: 30`
    *   Material: `ref: "mat_grass_green"`

### 2. Buildings

We define two types of buildings to demonstrate the flexibility of the JDA standard.

#### a) Primitive Building (`building_primitive.jda`)

A house built entirely from 3D primitives, demonstrating a simple approach.

*   **File:** `building_primitive.jda`
*   **Kind:** `sdf_csg_tree`
*   **Description:** A CSG (Constructive Solid Geometry) union of a cube for the body and a pyramid for the roof.
*   **Data (CSG Tree):**
    *   `op: "union"`
        *   **Node 1 (Body):** `sdf_primitive` (`box`), `material: "mat_wood_light"`
        *   **Node 2 (Roof):** `sdf_primitive` (`pyramid`), `material: "mat_roof_red"`, positioned on top of the body.

#### b) Hybrid SDF Building (`building_hybrid.jda`)

A more complex building that combines 2D SDF assets for facades and a 3D SDF asset for the roof. This is a core part of the PoC.

*   **File:** `building_hybrid.jda`
*   **Kind:** `sdf_csg_tree`
*   **Description:** A building constructed by extruding 2D SDF facades to create walls and combining them with a 3D roof.
*   **Data (CSG Tree):**
    *   `op: "union"`
        *   **Walls:** An array of 4 nodes. Each node is an `op: "extrude"` that references a 2D SDF asset (`ref: "facade_window.jda"`) and applies a position and rotation to form the building's perimeter.
        *   **Roof:** A reference to a 3D SDF roof asset (`ref: "roof_complex.jda"`), positioned on top of the walls.

#### c) Supporting Building Assets

*   **Facade (`facade_window.jda`)**
    *   **File:** `facade_window.jda`
    *   **Kind:** `sdf_2d`
    *   **Description:** A 2D SDF asset representing a single wall facade. It's a rectangle with smaller rectangles subtracted to create windows. This demonstrates the 2D SDF pipeline.
    *   **Material:** `mat_wall_beige`

*   **3D Roof (`roof_complex.jda`)**
    *   **File:** `roof_complex.jda`
    *   **Kind:** `sdf_3d`
    *   **Description:** A custom 3D SDF shape for a roof, demonstrating the use of non-primitive 3D SDFs.
    *   **Material:** `mat_roof_dark`

### 3. Trees (`tree_stylized.jda`)

Stylized trees made from simple primitives.

*   **File:** `tree_stylized.jda`
*   **Kind:** `sdf_csg_tree`
*   **Description:** A CSG union of a cylinder for the trunk and a sphere for the foliage.
*   **Data (CSG Tree):**
    *   `op: "union"`
        *   **Trunk:** `sdf_primitive` (`cylinder`), `material: "mat_wood_dark"`
        *   **Foliage:** `sdf_primitive` (`sphere`), `material: "mat_leaf_green"`, positioned on top of the trunk.

### 4. Materials (`materials.jda`)

All colors are defined in a central materials file for easy theming.

*   **File:** `materials.jda` (or defined within a `.game.json` bundle)
*   **Kind:** `material`
*   **Description:** A collection of simple, named color materials.
*   **Examples:**
    *   `mat_grass_green`: `color: [0.2, 0.6, 0.2]`
    *   `mat_wood_light`: `color: [0.8, 0.7, 0.5]`
    *   `mat_roof_red`: `color: [0.7, 0.2, 0.2]`
    *   `mat_leaf_green`: `color: [0.1, 0.5, 0.1]`
    *   `mat_wall_beige`: `color: [0.9, 0.85, 0.7]`
    *   `mat_wood_dark`: `color: [0.4, 0.2, 0.1]`
