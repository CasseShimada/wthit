---
audit_schema: 2
project: WTHIT
scope: "Fabric-only upgrade while preserving multi-loader architecture"
repository: "C:/Users/Admin/Documents/GitHub/wthit"
target_minecraft: "26.2"
target_loader: "Fabric Loader 0.19.3"
branch: "dev/26.2"
base_commit: "8a61749b37f38f670dbff0f23ec4ed752439663f"
last_verified_head: "eab1a6b3a53bc41815ee55ea18e5887580acee1e"
phase: "complete"
status: "complete"
last_updated: "2026-07-18T19:44:36+08:00"
working_tree: "GitHub Release 20.0.0 is published and independently verified; user-owned MIGRATION_PROMPT_26.2.md remains the only untracked file"
next_action: "No publication work remains; optionally complete the manual graphical-client compatibility matrix"
---

# WTHIT Fabric 26.2 Migration Audit

## 1. Executive summary

The WTHIT Fabric path is upgraded from Minecraft 26.1.1 to Minecraft 26.2 and validated against Java 25, Fabric Loader 0.19.3, and Fabric API 0.153.0+26.2. The final Fabric-only clean build, API artifacts, development test-plugin compilation, aggregate API Javadoc, dependency reports, JAR purity scans, two consecutive old-world dedicated-server runs, an exact-version 20.0.0 release-candidate run, and a final run using the downloaded GitHub Release asset succeeded.

This is deliberately not a whole-repository loader upgrade. Root common/API/Mixin/resources, `platform/mojmap`, `platform/textile`, `platform/fabric`, `platform/forge`, and `platform/neo` remain structurally present. Forge and NeoForge were neither configured by the Fabric-only build nor upgraded or runtime-tested. Their only source change is the minimal relocation of their public fluid helper into their owning API source set.

The final GitHub-released and server-tested binary is:

`https://github.com/CasseShimada/wthit/releases/download/20.0.0/wthit-26.2-fabric-20.0.0.jar`

- Size: 880,900 bytes
- SHA-256: `7816A72B854349663C0D9FF9DD74A3811820BD5696EACBEF0BA2FB7682E76C99`
- 649 unique entries, Java class major 69, no duplicates, no Forge/NeoForge/test/pluginTest/stub classes or metadata, and no forbidden constant-pool or `jdeps` references.

The Windows-local candidate is 880,908 bytes with SHA-256 `9C2DC2B06132256CCA71832FD8A979027554F31F3BB772F0859E90AB59EEF801`. Entry-by-entry comparison found exactly eight differences: each `META-INF/services/*` descriptor ends with CRLF locally and LF in the Linux Action build. Every class, metadata file, entry name, and all other resource contents are identical. The downloaded Linux-built asset itself passed the final dedicated-server run.

Remaining limitations are explicit: no graphical Fabric client was launched, so overlay rendering, configuration screens, keybinds, player permission behavior, actual client connect/disconnect/reconnect, and REI/JEI/Mod Menu interactions remain manual. Team Reborn Energy compiles and absence is safe, but an energy-capability-present runtime was not exercised. The original target had no pre-existing WTHIT configuration, so real legacy user-config parsing could not be demonstrated; generated WTHIT config was stable across repeated runs.

## 2. Repository snapshot

| Item | Evidence / result |
|---|---|
| Branch | `dev/26.2` |
| HEAD/base | base `8a61749b37f38f670dbff0f23ec4ed752439663f`; release tag `20.0.0` resolves to `eab1a6b3a53bc41815ee55ea18e5887580acee1e` |
| Initial worktree | No tracked/staged changes; only user-owned `?? MIGRATION_PROMPT_26.2.md` |
| Current worktree | Release code, workflow, and mirror correction are committed and pushed; only the user prompt remains untracked before this evidence-only audit update |
| Base relationship | `dev/master...dev/26.2` was `0 0`; merge base and HEAD were identical |
| `origin` | `https://github.com/CasseShimada/wthit` fetch/push |
| Canonical upstream | `https://github.com/badasintended/wthit.git` |
| Upstream heads at audit | master=`8a61749b`; dev/26.1=`3b138449`; no dev/26.2 head |
| dev/26.1 review | Six graph-only commits beyond merge base, five merges; only patch-unique change `33bde4e3` renames the root project for 26.1. No Fabric/Textile/common/Mixin/network/config fix required transplanting. |
| Shared fixes already in master | `bd9104f0`, `d0fd64f0`, `05835637`, `de687207`, `e8e1764d` |
| User file handling | `MIGRATION_PROMPT_26.2.md` was never modified |
| Push/publication | `dev/26.2` pushed through `eab1a6b3`; annotated tag `20.0.0` and stable GitHub Release `[26.2 Fabric] 20.0.0` published successfully |

Read-only evidence included `git status`, `git branch --all`, `git remote --verbose`, `git rev-parse HEAD`, `git log --graph --all`, `git cherry`, `git diff`, and canonical `git ls-remote`.

The migration and owning-platform API moves were committed in `40773069a2803127ce9ef98470e97d0e724afedb`; bounded CI retries followed in `74f5432549061f742f9d140ba57938ec5c233eca`; the verified official Modrinth mirror correction was committed in release-tagged `eab1a6b3a53bc41815ee55ea18e5887580acee1e`. The user-owned migration prompt was not staged.

## 3. Multi-loader architecture map

```text
root common project
  src/api + src/main + src/mixin + generated buildConst
  src/pluginCore + pluginExtra + pluginHarvest + pluginVanilla
  src/pluginTest (development only; never in production JAR by default)
                         |
                         v
platform/textile
  shared Fabric Transfer / viewer / Mod Menu / energy adapters
  owns mcp.mobius.waila.api.fabric.FabricFluidData
                         |
                         v
platform/fabric
  Fabric entrypoints, events, networking, services, plugin discovery, metadata
                         |
                         v
Fabric distribution and API JARs

platform/mojmap -> retained common Mojmap publication boundary
platform/forge  -> retained Forge services/plugins/resources and ForgeFluidData
platform/neo    -> retained NeoForge services/plugins/resources and NeoFluidData
```

- `setupPlatform()` still wires common outputs into loader projects without copying common sources.
- Production root source sets use an explicit allowlist: `api`, `main`, `minecraftless`, `pluginCore`, `pluginExtra`, `pluginHarvest`, and `pluginVanilla`. Mixin and generated constants are included where required.
- `pluginTest` is excluded unless `-PincludeTestPlugins=true`; tests and platform stubs are excluded from production binary/source artifacts.
- `-PenabledPlatforms=fabric` includes exactly root, `:textile`, and `:fabric`. It does not configure or resolve Forge, NeoForge, or Mojmap projects. Omitting the property preserves the normal all-enabled-platform graph, and unknown selector values fail early.
- CI's Fabric job uses `./gradlew :fabric:build -PenabledPlatforms=fabric --console=plain`.
- `apiJavadoc` aggregates owning-platform API source directories only for documentation and uses existing platform stubs only on its documentation classpath. Its generated docs include FabricFluidData, ForgeFluidData, and NeoFluidData without putting stubs or foreign APIs into the Fabric JAR.
- Forge/NeoForge code was not semantically rewritten. Moving their fluid API helpers out of the common source root is the minimum boundary correction needed to prevent foreign loader types from compiling or packaging into Fabric.

## 4. Fabric functionality matrix

Status terms: **server passed** means exercised in the isolated 26.2 dedicated server; **compile/static passed** does not claim graphical behavior; **manual** means not automatically exercised.

| Feature | Common implementation | Textile implementation | Fabric adapter | 26.2 impact / compatibility | Validation | Status |
|---|---|---|---|---|---|---|
| HUD / overlay | `gui/hud`, themes, renderers | viewer recipe actions | render/lifecycle callbacks | active GUI/HUD access moved behind `Minecraft.gui` | all sources/Mixins compile; production classes present | compile passed; visual manual |
| Block information | provider/accessor pipeline | Transfer lookup | network/event bridge | registry and block-entity holder names changed | common/Textile/Fabric compile; providers in dump | server initialization passed; client display manual |
| Entity information | vanilla/entity providers | none | lifecycle/network bridge | entity holder/data APIs changed | compile + dump provider registration | server initialization passed; client display manual |
| Item information | vanilla/`pluginExtra` providers | `ItemStorageProvider` | Fabric plugin registration | data components and storage APIs | compile; provider appears in server dump | server registration passed; client display manual |
| Fluid information | `FluidData` and descriptors | `FluidStorageProvider`, `TextileFluidDescriptor` | Fabric API helper/plugin | Transfer API and component patch | API compile/JAR/Javadoc + dump provider | server registration passed; displayed values manual |
| Energy information | `EnergyData` | Team Reborn Energy provider | required-mod plugin gating | third-party API 5.0.0 | compile; server starts without energy API/viewer mods | absence passed; presence manual |
| Tooltips/components | public API/renderers | viewer actions | client entrypoints | GUI/render mappings | compile + JAR/API scans | compile passed; visual manual |
| Harvest capability | `pluginHarvest` | none | Fabric lifecycle/tag path | tool predicates/tags changed | compile; plugin initializes | server initialization passed; result display manual |
| Configuration files | JSON5 config stack | Mod Menu adapter | Fabric config directory | format/keys intentionally unchanged | generated files stable over repeated runs | generated-config idempotence passed; legacy user config unavailable |
| Configuration UI | screens/widgets/themes | Mod Menu entrypoint | client initializer | layout/tab APIs changed | all screens compile | manual |
| Client commands/keybinds | common client command | none | Fabric client callback | command/GUI mappings changed | compile only | manual |
| Server commands | common/server command | none | Fabric command callback | command/item predicate changes | console executed `waila plugin list` and `waila dump` in passes 5/6 and exact-release pass 7 | server passed |
| Permissions | command requirements | Fabric permission API | Fabric command registration | API module retained | dependency/compile and console execution | compile passed; player permission matrix manual |
| Networking | protocol 10 payloads/codecs | none | Fabric networking | registration/context compatibility | compile and dedicated server registration/start | server passed; client handshake/reconnect manual |
| Plugin discovery | common loader | Textile built-ins | Fabric metadata/JSON/ServiceLoader | loader metadata/API | dump and logs show core/vanilla/harvest/extra/fabric | server passed |
| Third-party plugin API | `src/api`, descriptors, ServiceLoader | Fabric fluid helper | service implementations/stub API JAR | loader-specific API boundary corrected | API JAR/source JAR/Javadoc and ServiceLoader target scans | static passed |
| Resource reload | common services/Mixins/themes | none | Fabric reload/tag callbacks | listener signatures | compile and initial resource/tag lifecycle | initial lifecycle passed; explicit client reload manual |
| Lifecycle/ticks | common client/server lifecycle | none | Fabric events | event signatures | two final server starts/stops | server passed; client ticks manual |
| Connect/disconnect | client/network state | none | connection events | networking context | compile only | manual |
| Tags/registries | filters, harvest cache, vanilla plugins | storage lookup | tag/lifecycle callbacks | plural holder classes and lookup changes | compile and world load | server startup passed; explicit reload manual |
| REI | recipe action API | restored 26.2 adapter | optional `rei_client` entrypoint | REI 26.2.820 | compile-only adapter; optional runtime graph resolves exact artifact | compile/dependency passed; client manual |
| JEI | restored common adapter | none | optional `jei_mod_plugin` entrypoint | JEI 30.10.0.60 | compile-only adapter; optional runtime graph resolves exact artifact | compile/dependency passed; client manual |
| EMI | retained commented source/TODO | no usable adapter | no dangling entrypoint | no official 26.2 artifact found | metadata/class/JAR scans | unavailable; core unaffected |
| Missing optional viewers | default recipe action behavior | optional adapters | Loader skips absent entrypoints | no hard dependency permitted | final server has no REI/JEI/EMI/Mod Menu/Energy JAR | server passed |

No original Fabric core implementation was deleted, replaced with an empty implementation, or bypassed. The only unavailable integration is EMI, whose 26.2 dependency does not exist; its source/TODO remains for future re-enable.

## 5. Minecraft 26.2 API changes

| Area | Applied result | Evidence/status |
|---|---|---|
| Mappings/artifact | Minecraft 26.2 is unobfuscated; project remains on Loom's official namespace with no Yarn declaration. The distribution task is `:fabric:jar`, not a legacy remap output. | final JAR classes and build tasks passed |
| Java | Toolchain/release stays Java 25; class major is 69. | local/target Java 25; artifact scan |
| Loom/Gradle | Loom 1.17.16 and Gradle wrapper 9.5.1. | official Fabric 26.2 guidance specifies Loom 1.17/Gradle 9.5.1; clean build passed |
| Loader/FAPI | Loader 0.19.3, Fabric API 0.153.0+26.2. | exact target environment and resolved graphs |
| GUI/HUD | active screen, toast, and HUD access moved through `Minecraft.gui`; tab screens use `MenuTabBar`, layout, and `FrameLayout`. | all client sources compile; visual manual |
| Translation lookup | `I18n.exists` replaced by `Language.getInstance().has`. | compile passed |
| Registries/blocks | `EntityTypes`, `BlockEntityTypes`, and color-family access such as `Blocks.WOOL.black()`. | compile passed |
| Commands/predicates | `DataComponentMatchers` and `ItemPredicate` use their 26.2 predicate packages. | server/client commands compile; server commands run |
| Transfer/data components | Fabric Transfer 8.0.11 APIs and `DataComponentPatch` are used by Textile/Fabric fluid APIs. | Textile/API compile and server provider dump |
| Networking | Existing payload IDs/codecs and network version 10 retained; Fabric registration compiles and server loads. | server passed; client connection manual |
| Mixins | Existing `wthit.mixins.json` retained; Mixin 0.8.7 initializes with no apply error in final server logs. | server passed; client-only targets not visually exercised |
| Access widener | WTHIT declares no access widener and none was invented. | source/resource/final metadata scan |
| Dedicated server isolation | ServiceLoader and Fabric entrypoints load on `Env=SERVER` without client-class errors. | passes 5/6 and exact-release pass 7 have zero runtime failure matches |

Primary version evidence: [Fabric 26.2 migration guidance](https://fabricmc.net/2026/06/15/262.html), [Fabric Loom metadata](https://maven.fabricmc.net/net/fabricmc/fabric-loom/maven-metadata.xml), [Fabric Loader metadata](https://maven.fabricmc.net/net/fabricmc/fabric-loader/maven-metadata.xml), and [Fabric API metadata](https://maven.fabricmc.net/net/fabricmc/fabric-api/fabric-api/maven-metadata.xml).

## 6. Fabric dependency audit

| Dependency | Previous | Target | Purpose | Compatibility evidence | Runtime? | Final status |
|---|---:|---:|---|---|---|---|
| Minecraft | 26.1.1 | 26.2 | game/API | real target and official metadata | yes | resolved/server passed |
| Fabric Loader | 0.18.6 | 0.19.3 | loader | exact target; Mixin 0.17.3+mixin.0.8.7 | yes | server passed |
| Fabric API | 0.145.3+26.1.1 | 0.153.0+26.2 | events/network/transfer/render | exact target chosen instead of drifting to latest | yes | resolved/server passed |
| Gradle | 9.4.0 | 9.5.1 | build | official 26.2 guidance | build only | passed |
| Fabric Loom | 1.15.5 | 1.17.16 | build/mappings | latest stable 1.17 release in provider metadata | build only | passed |
| Java | 25 | 25 | compile/runtime | target/FAPI require 25 | yes | passed |
| badpackets | 0.12.2 | 0.12.2 | packet abstraction | provider metadata supports modern Loader/MC | yes | exact target JAR loaded; passed |
| Mod Menu | 18.0.0-alpha.6 | 20.0.1 | config-screen integration | provider release targets 26.2/Loader >=0.19.2 | optional client | compile passed; runtime manual |
| REI | 13.0.666 | 26.2.820 | recipe display | provider POM targets 26.2/Java 25 | optional client | compile and optional graph passed |
| JEI | 1.20.2-16.0.0.28 | 26.2-30.10.0.60 | recipe display | its FAPI floor 0.152.2 fits selected 0.153.0 | optional client | compile and optional graph passed |
| EMI | 1.0.23+1.20.2 | none | recipe display | no official 26.2 artifact/branch/tag found | no | dependency/entrypoint excluded; source retained |
| Team Reborn Energy | 5.0.0 | 5.0.0 | optional energy lookup | current API compiles with target Transfer API | optional | compile/absence passed; presence manual |
| Forge | 63.0.1 | unchanged/out of scope | retained platform | must not enter Fabric graph/JAR | no | not configured/packaged |
| NeoForge | 26.1.1.6-beta | unchanged/out of scope | retained platform | must not enter Fabric graph/JAR | no | not configured/packaged |

Fabric metadata now requires Loader `>=0.19.3`, Fabric API `>=0.153.0`, Minecraft `~26.2-`, Java `>=25`, and badpackets `>=0.12.2`. CurseForge/Modrinth publication tags advertise Fabric only; Mod Menu, REI, and JEI are optional. The previous Quilt publication claim was removed because Quilt was not tested.

## 7. Build isolation audit

The pre-migration baseline command `gradlew.bat :fabric:build --console=plain --stacktrace` exited 1 before compilation because the obsolete EMI 1.20.2 download ended prematurely. It was recorded twice and was not misclassified as a Minecraft 26.2 source error.

The implemented selector in `settings.gradle.kts` accepts `-PenabledPlatforms=fabric`, expands Fabric to its required Textile project, and includes exactly root/Textile/Fabric. Default behavior still includes every normally enabled platform. The Fabric target neither applies Forge/NeoForge build plugins nor resolves their Maven dependencies.

Reproducible commands:

```powershell
.\gradlew.bat projects -PenabledPlatforms=fabric --console=plain
.\gradlew.bat :fabric:dependencies --configuration compileClasspath -PenabledPlatforms=fabric --console=plain
.\gradlew.bat :fabric:dependencies --configuration runtimeClasspath -PenabledPlatforms=fabric --console=plain
.\gradlew.bat :fabric:clean :textile:clean :fabric:build -PenabledPlatforms=fabric --console=plain --rerun-tasks
```

All target commands exited 0. The clean build executed 24 tasks across only root, Textile, and Fabric. CI and docs use the selector. README documents Fabric-only builds, default all-platform behavior, automatic Textile inclusion, and the development-only plugin opt-in.

## 8. Persistence and configuration compatibility

Static scan found no WTHIT `SavedData`, dimension storage, persistent player data, or custom world-file writes. NBT/data components carry transient provider/network data. Filesystem writes are limited to configuration and debug-dump paths. The old-world test is nevertheless required and passed because mixin, registry, provider, and third-party-mod interactions can still affect loading.

| Compatibility item | Original | 26.2 target/result | Changed? | Validation | Status |
|---|---|---|---:|---|---|
| Fabric Mod ID | `wthit` | same; still provides `waila` | no | final metadata/server mod list | passed |
| Resource/network namespace | `waila` | same | no | source/JAR scans | passed static |
| Assets namespace | `assets/waila` | same | no | final JAR scan | passed static |
| Config root/files | Fabric config + `waila/*.json5`; dump in `.waila/` | same | no | repeated isolated runs | generated config stable |
| Config schema/keys | Waila config version 1 and existing IDs | same | no migration added | source/diff/runtime | passed static/generated |
| Network protocol | `NETWORK_VERSION = 10` | 10 | no | source/JAR | passed static; client handshake manual |
| Packet IDs | existing `waila:*` payload IDs | same | no | source/JAR | passed static |
| Plugin descriptors/IDs | JSON descriptors and `waila:core/vanilla/harvest/extra/fabric` | same | no | server logs/dump | passed |
| Public API | common API plus loader fluid helpers | same classes, moved to owning source sets | location only | API JAR/source/Javadoc | passed |
| Registry objects | no WTHIT game registry objects found | none added | no | source scan/world load | passed |
| World/player data | none written by WTHIT | none added | no | source scan and repeated old-world save | passed |

The real target's original world aggregate SHA-256 was `4BB0D4058E64314B8DACD367141AB2745D4BC14E40A37D91C8E15FA3DB192A5B` before copying and remained identical after validation checks. Its config aggregate SHA-256 was and remained `1F58B489A53D1F0FA646768D4E8FCE6D852F593ABF88D26458A70A3CE151BE72`. The final passes execute only inside the guard-checked isolation directory.

The original target had no `config/waila` tree, so legacy WTHIT user-config compatibility is not claimed from runtime evidence. The isolated generated WTHIT config aggregate was `2A1EBAC47AB100D7968E058288EDD2F1A8C9A94FB5B8C7343897FAEB09C8D4FD` before and after an additional run and remains exactly that value after final passes 5/6 and exact-release pass 7. The server rewrites normal config timestamps during shutdown, but the relative-path/length/content-hash manifest is byte-idempotent.

## 9. Migration plan and change log

- [x] Create/resume `dev/26.2` at current `dev/master` without overwriting the user prompt.
- [x] Audit Git/remotes/upstream dev/26.1; no patch transplant required.
- [x] Record the 26.1.1 Fabric baseline and obsolete EMI failure.
- [x] Complete architecture, feature, API, dependency, build-isolation, persistence, and target audits before implementation.
- [x] Upgrade Minecraft/Loader/FAPI/Loom/Gradle and Fabric metadata/publication metadata.
- [x] Add explicit Fabric-only settings selection while preserving the multi-loader graph.
- [x] Correct production source-set isolation and move public fluid helpers to owning platform API source sets.
- [x] Port common/Textile/Fabric GUI, command, predicate, registry, item/data-component, REI, and JEI code to 26.2.
- [x] Compile production and development-only source sets; build binary/source/API artifacts and Javadoc.
- [x] Resolve default, REI, and JEI runtime graphs without Forge/NeoForge.
- [x] Scan final artifacts and `jdeps` for duplicates, foreign loader content, tests, stubs, class version, metadata, and ServiceLoader integrity.
- [x] Create a unique isolated server copy without modifying the real environment.
- [x] Load/save/stop the copied old world twice with the exact final artifact (passes 5 and 6).
- [x] Exercise plugin listing, debug dump, save-all, missing optional viewers, and clean stop.
- [x] Record all graphical/client-only items as manual rather than claiming success.
- [x] Complete this audit; no push.

Key change sequence:

| Time (+08:00) | Change/evidence | Scope/other loaders | Result |
|---|---|---|---|
| 15:26-17:16 | Branch/upstream/baseline/audit gate | read-only | correct base; no transplant |
| 17:25-17:34 | Target versions, selector, metadata, CI, API-source ownership, source-set allowlist | Forge/Neo API files moved only | root/Textile/Fabric graph resolves |
| 17:36-17:42 | Java 26.2 ports and clean builds | common changes compile through Fabric; other loaders not configured | build/API/JAR tasks pass |
| 18:04-18:11 | Authoritative isolation and initial repeated server validation | isolated copy only | server behavior/config/world checks pass |
| 18:14-18:24 | Optional viewer selector fix, publication range/tags, final clean artifact scans | Fabric build metadata only | exact REI/JEI graphs and pure final JAR |
| 18:26 | Exact final JAR copied only to isolate; passes 5/6 | original target untouched | both final old-world runs pass |
| 18:31-18:33 | Platform API Javadoc aggregation and workflow trigger | documentation uses stubs only | all three loader fluid helpers documented |
| 19:00-19:05 | Prepared stable version 20.0.0 and Fabric-only tag release workflow; built and server-tested the exact release candidate | GitHub-only publication; no external publisher or other-loader task | candidate and Action static validation pass; push/tag still pending |
| 19:15-19:21 | Pushed migration and bounded-retry commits; observed two head Action failures | no release tag pushed | both failures isolated to truncated Terraformers Maven responses for Mod Menu 20.0.1 |
| 19:27-19:30 | Replaced the compile-time Mod Menu source with its official Modrinth Maven coordinate and rebuilt exact 20.0.0 | dependency bytes verified identical; no packaged dependency change | all 31 tasks pass and release hashes remain identical |
| 19:33-19:39 | Pushed mirror commit, passed head Action, pushed annotated tag, and completed tag-triggered release Action | GitHub-only Fabric publication | branch run `29642767047` and release run `29642871771` pass; stable Release created |
| 19:40-19:44 | Downloaded both GitHub assets, verified digests and ZIP differences, scanned the main JAR, and ran exact released asset in the isolate | released binary itself tested | pass 8 exits 0, clean stop, five plugins, zero runtime failures |

Three earlier isolation directories are intentionally preserved because deletion was forbidden:

- `wthit-fabric-26.2-test-20260718-174600`: first controller's inline event handling failed after the server reached Done; world chunks were saved. This was a controller failure, not accepted runtime evidence.
- `wthit-fabric-26.2-test-20260718-175200` and `...-180000`: controller log-sharing reads timed out; fallback stop was clean. These are not classified as WTHIT migration failures.
- Authoritative isolate: `wthit-fabric-26.2-test-20260718-180400`.

## 10. Validation evidence

| Validation | Command / evidence | Exit | Key result |
|---|---|---:|---|
| Baseline | `:fabric:build` on 26.1.1 | 1 | obsolete EMI download failed before compilation; logs under `build/migration-logs/baseline-*` |
| Project isolation | `projects -PenabledPlatforms=fabric` | 0 | exactly root, Textile, Fabric |
| Compile/runtime graphs | `:fabric:dependencies --configuration compileClasspath/runtimeClasspath` | 0 | MC 26.2, Loader 0.19.3, FAPI 0.153.0, badpackets 0.12.2; no Forge/NeoForge |
| Optional REI graph | runtimeClasspath with `-PrecipeViewer=rei` | 0 | `RoughlyEnoughItems-fabric:26.2.820`; `fabric-runtime-rei-26.2-final.log` |
| Optional JEI graph | runtimeClasspath with `-PrecipeViewer=jei` | 0 | `jei-26.2-fabric:30.10.0.60`; `fabric-runtime-jei-26.2-final.log` |
| Final clean build | `:fabric:clean :textile:clean :fabric:build -PenabledPlatforms=fabric --rerun-tasks` | 0 | 24/24 executed; `migration-fabric-build-26.2-final.log` |
| Pre-release final-state build | `:fabric:build -PenabledPlatforms=fabric` after the Javadoc-only script change | 0 | migration worktree configured/built; its local-version binary was SHA-256 `A0B9F7E3...C8E6` before version finalization |
| Exact 20.0.0 candidate | `MOD_VERSION=20.0.0` with clean Textile/Fabric, root test, pluginTest compile, translation validation, Fabric build, and API JAR | 0 | release candidate SHA-256 `9C2DC2B...F801`; `release-candidate-20.0.0-build.log` |
| Mirror-corrected exact candidate | same release command after switching Mod Menu to `maven.modrinth:mOgUt4GM:njXb639R` | 0 | 31 tasks executed; main/API hashes remain exactly `9C2DC2B...F801` / `1056477E...1138` |
| Workflow lint | actionlint 1.7.12 over all three workflow files | 0 | release workflow valid; two pre-existing head/docs defects were minimally corrected |
| Remote head Action | run `29642767047` for `eab1a6b3` | 0 | Fabric build and artifact upload pass in 2m05s |
| Tag release Action | run `29642871771` for `20.0.0` / `eab1a6b3` | 0 | full build/test, artifact scan, workflow artifact, and GitHub Release publication pass in 2m24s |
| Downloaded release assets | `gh release download 20.0.0` plus SHA-256, ZIP-entry, metadata, and local `jdeps` checks | 0 | GitHub digests match downloads; 649 unique main entries; zero forbidden dependency hits |
| Tests/API artifacts | `:test :validateTranslation :fabric:apiJar :fabric:apiSourcesJar` | 0 | tests up-to-date, translation validator reports pre-existing missing translations but succeeds, API artifacts generated |
| Dev plugin source | `:compilePluginTestJava -PenabledPlatforms=fabric` | 0 | changed pluginTest sources compile while staying out of production JAR |
| API docs | `apiJavadoc -PenabledPlatforms=fabric` | 0 | Fabric/Forge/Neo fluid helper HTML generated; only external link redirect warning |
| Binary scan | ZIP entry/duplicate/constant-pool/class-major/metadata scan | 0 | 649 entries, 0 duplicates/forbidden, major 69, exact Fabric metadata |
| `jdeps` | `jdeps --ignore-missing-deps -verbose:class <20.0.0.jar>` | 0 | 0 Forge/NeoForge/test hits; `release-candidate-20.0.0-jdeps.log` |
| Diff hygiene | `git diff --check` | 0 | no whitespace errors; Git only warns about future LF-to-CRLF conversion |
| Final server pass 5 | validation script, authoritative isolate | 0 | Done=1, clean stop=true, forced=false, runtime failures=0 |
| Final server pass 6 | same old-world isolate after save | 0 | Done=1, clean stop=true, forced=false, runtime failures=0 |
| Exact release pass 7 | exact 20.0.0 candidate copied only into authoritative isolate | 0 | WTHIT 20.0.0, Done=1, five plugins, dump/save, clean stop, forced=false, runtime failures=0 |
| Published release pass 8 | downloaded GitHub main asset copied only into authoritative isolate | 0 | WTHIT 20.0.0, Done=1, five plugins, dump/save, clean stop, forced=false, runtime failures=0 |

Final artifact inventory:

| Artifact | Bytes | SHA-256 | Entries | Purity |
|---|---:|---|---:|---|
| GitHub asset `wthit-26.2-fabric-20.0.0.jar` | 880,900 | `7816A72B854349663C0D9FF9DD74A3811820BD5696EACBEF0BA2FB7682E76C99` | 649 | passed and server-tested |
| Local-only `wthit-26.2-fabric-20.0.0-sources.jar` | 425,590 | `03FE8015B66DB8103FC229E9F50CD806C5BE743F23FD854BA6B5EFBD3ED4CFCA` | 505 | passed |
| GitHub asset `wthit-26.2-fabric-20.0.0-api.jar` | 118,219 | `1056477E0AC7E9FC1882422927CB795F905038FC784FD3F8BE70DD5914E81138` | 140 | passed |
| Local-only `wthit-26.2-fabric-20.0.0-api-sources.jar` | 69,038 | `610AD714A2E9BADAAC623D0AC56EF1266AE7ABD3A7CA0B1F47DE15569BC542F8` | 95 | passed |

Final server evidence:

- Isolate: `C:/Users/Admin/AppData/Local/Programs/Minecraft_Client/PCL2/.minecraft/versions/wthit-fabric-26.2-test-20260718-180400`
- Isolation bind/port: `127.0.0.1:25625`, modified only in the isolate.
- Pass 7's local release-candidate JAR hash in the isolate exactly equals `9C2DC2B0...F801`; pass 8's downloaded GitHub asset exactly equals its published digest `7816A72B...6C99`.
- Pass 5 stdout: 9,662 bytes, SHA-256 `90C0D93462FB2C96529910F261AF4E3C40770541E7876F3F7C04FC74410267A8`.
- Pass 6 stdout: 9,663 bytes, SHA-256 `2C3DF7D1A4A5DF85D874C32F90F30A0DC2A94855234AC08D5BECED5DCCD68EBC`.
- Pass 7 stdout: 9,656 bytes, SHA-256 `0762DEBB8949CB91FC650B053790ACC5D3C428F607E6629CC7A9BA03906BCEAB`.
- Pass 8 stdout: 9,656 bytes, SHA-256 `70CB0922BDA8C4D3E8E44442843DCD8C90079E3C3F31489AC18858ECE08368E2`.
- Passes 5-8 stderr: 523 bytes each, SHA-256 `37CD8362F1166B48D04CC268E22CB21452842093BF6C3C31AF8A0648E91BE422`; they contain JVM native-access warnings, not server/WTHIT failures.
- Passes 5/6 show the final local build, pass 7 shows the exact local 20.0.0 candidate, and pass 8 shows the downloaded GitHub Release asset; all show Minecraft 26.2, Loader 0.19.3, badpackets 0.12.2, Mixin 0.8.7, five WTHIT plugins, all-dimension saves, and clean stop.
- Commands per pass: `waila plugin list`, `waila dump`, `save-all flush`, `stop`.
- Latest published-release dump: 3,463 bytes, SHA-256 `C0EEB55AE2AC7DDF7DC08D72420EF0ADA8D71D3BE3198BEAE587200185EE46C8`; it records MC 26.2, Java 25, Loader 0.19.3, WTHIT 20.0.0, five plugins, FluidStorageProvider, and ItemStorageProvider.

The target isolate also retained its existing 26.2 Aether, Carry On, Kaleidoscope Cookery, and Twilight Forest mods, so the final smoke test was not an empty synthetic server. REI, JEI, EMI, Mod Menu, and Team Reborn Energy were absent, proving only safe absence behavior.

Release publication evidence:

- Repository version-family history supports stable `20.0.0` for the new Minecraft 26.2 compatibility family; `majorVersion` and the top changelog entry now match.
- `.github/workflows/release.yml` listens for `20.*.*` tag pushes, independently validates numeric SemVer and changelog presence, builds/tests only root/Textile/Fabric with `MOD_VERSION`, repeats JAR purity and `jdeps` checks, uploads the main/API workflow artifact, and creates a GitHub Release using the scoped `github.token`.
- The workflow deliberately does not run Maven, CurseForge, or Modrinth publication. The fork has none of the four external publisher secrets, and the removed historical workflow would incorrectly build all loaders.
- `workflow_dispatch` remains declared for future use after the workflow reaches the default branch. The initial release correctly used a tag push because GitHub only dispatches workflows that already exist on the default branch.
- actionlint 1.7.12 reports all three workflows valid. It also exposed and prompted minimal fixes for the pre-existing unsupported pull-request tag filter and missing docs step output.
- The first remote `head` run (`29642231111`, commit `40773069`) reached Gradle configuration but failed downloading Mod Menu 20.0.1 because Terraformers Maven closed a chunked response prematurely. The second run (`29642336445`, commit `74f54325`) retried the identical command three times with bounded 10/20-second backoff and received the same truncated response each time. These are external transfer failures, not source failures; both runs correctly blocked publication.
- Mod Menu 20.0.1's official Modrinth version page exposes Maven coordinate `maven.modrinth:mOgUt4GM:njXb639R`. Its 614,002-byte JAR has SHA-256 `81BFBCA06012C57C74949072F2FFAAD06360BADEE4D00DC59BFAEAC80DD24BD8`, exactly matching the previously resolved Terraformers artifact. The repository now resolves that group exclusively from `https://api.modrinth.com/maven`; the dependency remains compile-only for Fabric/Textile and does not alter the release JAR.
- After the mirror correction, the full exact-version release command passed locally and reproduced the already server-tested local main/API hashes. actionlint still reported all workflows valid; this evidence and the subsequent green head run gated the release tag.
- Head run `29642767047` passed for `eab1a6b3`, after which annotated tag `20.0.0` was pushed to that exact commit. Release run `29642871771` passed every build, inspection, upload, and publication step.
- Stable, non-prerelease GitHub Release `[26.2 Fabric] 20.0.0` was published at `https://github.com/CasseShimada/wthit/releases/tag/20.0.0` with the main and API JARs. GitHub's recorded SHA-256 digests match independent downloads.
- The Linux Action main JAR differs from the Windows candidate only by LF versus CRLF in eight ServiceLoader descriptors. The released asset's own purity/metadata/`jdeps` scans and dedicated-server pass 8 succeeded.

Manual release matrix still required for stronger client confidence:

1. Launch a Fabric 26.2 client with the final JAR and badpackets/FAPI.
2. Join the isolated server twice and verify connect/disconnect/reconnect and network version exchange.
3. Inspect block/entity/item/fluid/harvest overlays and theme placement.
4. Open every WTHIT configuration tab, Mod Menu entry, keybind, and client command.
5. Trigger resource reload and verify cached tag/provider state.
6. Repeat separately with REI 26.2.820 and JEI 30.10.0.60; verify recipe input/output actions.
7. Add a compatible Team Reborn Energy implementation and verify an energy-capable target.
8. Test command permissions as non-op/op players.

## 11. Model continuation area

- Current phase/status: `complete` / `complete`.
- Release-tagged code/workflow HEAD: `eab1a6b3a53bc41815ee55ea18e5887580acee1e`; this evidence-only audit update may advance `dev/26.2` while tag `20.0.0` remains correctly fixed to the released commit.
- Preserve user-owned `MIGRATION_PROMPT_26.2.md`.
- Do not rerun the obsolete EMI baseline or treat missing EMI 26.2 as a core failure.
- Do not delete the three controller-test directories or authoritative isolate.
- Never modify the real target's world, mods, config, server.properties, launcher, or logs.
- Keep the user prompt untracked when staging this evidence-only audit update.
- Other loaders remain retained but unvalidated. Do not claim Forge/NeoForge/Quilt 26.2 compatibility.
- Publication is complete. No tag, release, or asset replacement is pending. Optional client work remains the manual matrix above.
