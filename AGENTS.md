# Repository Guidelines

## Project Structure & Module Organization
- Top-level numbered folders (`1_town`, `2_fps`, `3_caves`, `4_themed_assets`, `5_mountains`, `6_solarsystem`) each hold a self-contained sample: `*.jdw.json` scenes/areas, `*.jda.json` assets/materials, and optional `*.axsl.json` shaders.
- `docs/axiumdocs_shared/` contains the AXIUMDOCS reference set (`Standards/`, `refs/`, `archive/`) and supporting Markdown such as `sdf_2d_to_3d_techniques.md`.
- Keep new scenes alongside peers by adding a numbered folder with matching JDW/JDA/AXSL files; reuse shared docs rather than duplicating them.

## Build, Test, and Development Commands
- No build pipeline required; files are plain JSON/Markdown.
- Quick file survey: `rg --files -g '*.json'` (JSON assets) and `rg --files -g '*.md' docs` (docs inventory).
- JSON validity check (fail-fast): `python -m json.tool 1_town/town.area.jdw.json` or `jq . 2_fps/arena.jda.json`.
- Linkage sanity check: `rg '"asset":' 1_town/town.area.jdw.json` and confirm referenced asset IDs exist in sibling `*.jda.json`.

## Coding Style & Naming Conventions
- Use 2-space indentation, lowercase snake_case filenames and IDs (e.g., `mountain_range.jda.json`, `solarsystem.area.jdw.json`).
- Maintain consistent `type` markers (`jdw.scene`/`jdw.area`, `jda.asset`, shader `axsl` files) and keep `"id"` values stable for cross-file references.
- Prefer nested nodes/assets over duplication; share materials via `materials.jda.json`.
- Markdown: concise headings/bullets, relative links, wrap lines near 120 chars, and keep paper copy markers intact.

## Testing Guidelines
- Validate every touched JSON with `python -m json.tool <file>`; avoid trailing commas and ensure arrays use numeric types where intended.
- For scenes, scan for orphaned IDs by grepping `asset`/`material` references against sibling files.
- For docs in `docs/axiumdocs_shared/`, open rendered Markdown locally to confirm images (`images/` paths) and code blocks display correctly.

## Commit & Pull Request Guidelines
- Use imperative, descriptive messages: `Add solar system orbital animations`, `Refine mountain materials`.
- Summaries should mention the folder touched and the asset/scene IDs adjusted; link issues or tasks when present.
- PRs should include: scope of change, validation steps run (e.g., `python -m json.tool …`), and before/after notes if visuals or node layouts changed.
