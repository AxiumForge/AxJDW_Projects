# AXIUMDOCS Project Overview

This repository, `AXIUMDOCS`, serves as a comprehensive documentation hub for various standards, research references, and internal guidelines related to game development, particularly focusing on JDW (world/scene/level data) and JDA (asset data). It is a non-code project primarily composed of Markdown documents.

## Directory Overview

*   `AXIUMDOCS/shared/refs/`: Contains source papers and research references, typically converted to Markdown. Each subdirectory within `refs` corresponds to a specific paper or topic (e.g., `3dgs_zip_compression_survey_2024`, `hdr_gs_2024`, `kerbl_2023_3d_gaussian_splatting`), including an `index.md` and an `images/` folder for figures.
*   `AXIUMDOCS/shared/Standards/`: Houses various standards and policy documents.
    *   `JDW_JDA_Legacy_Standard_v0_1.md`: This key document outlines the transition from an older "JDW SDF/CSG World-Building Standard" to a newer, simplified "JDW/JDA Standard v0.1". It details the structure and purpose of JDW and JDA, introduces an intermediate `.game.json` format for development, and a `.axgame` (libsql) distribution format for finished products. It also covers the JDA SDF sprite animation format (`.anim.json`).
    *   `JDW_JDA_Standard_v0_1.md` (implied): The target for the new core standard that the legacy document refers to.
*   `AXIUMDOCS/shared/archive/`: Contains older, superseded standards, such as `jdw_sdf_csg_world_standard_v_0.md`.
*   `AXIUMDOCS/AGENTS.md`: Provides guidelines for the repository's structure, naming conventions, testing, and contribution process.

## Key Concepts and Formats

*   **JDW (Jade World):** Represents world, scene, and level data in a game.
*   **JDA (Jade Asset):** Encompasses all asset data, including SDF/CSG definitions, meshes, materials, animations, audio, and shaders.
*   **`.game.json`:** An all-in-one intermediate JSON format used during development and testing to bundle JDW, JDA, and shader data for quick iteration.
*   **`.axgame` (libsql):** The final distribution format for games, utilizing a SQLite database to store all JSON entities, vectors, and blobs efficiently. It is designed for cloud synchronization and LLM-friendliness.
*   **`.anim.json`:** A JDA-compatible format for SDF-based sprite animations, supporting both frame-based and parametric approaches.

## Usage

This documentation serves as a foundational resource for understanding and implementing the data structures and standards for game development within the project. Developers and contributors should refer to these documents to ensure consistency in data formats, asset management, and the overall architecture of game content. The guidelines provided in `AGENTS.md` should be followed for all contributions to this repository.

### Build, Test, and Development Commands (from AGENTS.md)

*   **No build pipeline required:** Markdown renders directly.
*   **Quick checks:**
    *   `rg --files -g '*.md' shared`: Confirm Markdown file placement.
    *   `rg 'images/' shared/refs/<slug>/index.md`: Verify relative figure references.
    *   `ls shared/refs/<slug>/images | wc -l`: Check image counts.

### Coding Style & Naming Conventions (from AGENTS.md)

*   Use concise Markdown with headings, bullets, and fenced code blocks.
*   File names should be lowercase snake_case; papers include a year suffix.
*   Maintain relative paths for images.

### Testing Guidelines (from AGENTS.md)

*   Manually open `.md` files to confirm rendering.
*   Preserve pagination markers (`<!-- Page X -->`) when copying paper text.
*   Keep new sections under ~120 characters per line.