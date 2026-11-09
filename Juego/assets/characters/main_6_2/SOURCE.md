# Human student assets — DuocGames 6.2

Data source: https://github.com/kblood/CharacterCreator/tree/master/output

Author/exporter: Kasper Olesen / kblood. Base human, rig, weights, eyes, brows, lashes, teeth, tongue, clothing and hair derive from the MakeHuman system assets (makehuman_system / MakeHuman Community).

License: **CC0-1.0 for generated GLB assets and animation data**. See the bundled unmodified `LICENSE-NOTES.md` and `asset_licenses.json`. The upstream program code has a separate GPL license. No upstream program code, plugin, viewer, or generator was copied into DuocGames.

Original downloaded data: body with 53-bone rig and locomotion clips, hoodie, T-shirt, jeans, shoes, short02/short04/long01 hair. Exact upstream Git blob hashes are in `../../../reports/main_character_6_2/asset_hashes.json`; the build manifest records local derivatives too.

Local conversion: the independently written `tests/prepare_human_assets_6_2.cjs` decodes integer-normalized morph accessors into floats and retains seven relevant morphs. `tests/bake_human_6_2.gd` parses these GLBs with Godot GLTFDocument and saves compressed native PackedScene `.scn` resources. `source/` contains intermediate GLBs excluded from automatic editor import by `.gdignore`; the game loads `native/*.scn`.

The native source clips remain available, but the integrated player uses a live retargeting layer driven by its existing procedural pose controller to preserve attack timing, crouching and contextual actions. This is not a claim that all upstream animation clips are played in-game.

Hoodie source uses a MakeHuman sweater plus a generated folded hood; its knit/rib/pocket/seam texture is generated upstream. Jeans and shoes include source textures. The white/grey shoe material is a local luminance shader over the original footwear texture. Footwear geometry is inherited lace-up casual footwear, not an exact recreation of the reference sneakers.

The backpack is the existing DuocGames procedural backpack, with adjusted straps and a darker material. Reference art supplied by the user is kept only with the comparison reports; no logo from it is used on the model.
