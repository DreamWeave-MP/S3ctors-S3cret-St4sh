---
title: Historical Evidence Index
description: A map from Cod3x engineering rules back to the repository history that motivated or tested them.
weight: 40
extra:
  kind: reference
---

Cod3x is deliberately willing to cite ugly intermediate history.

This is not a changelog. It is an index of commits that are especially useful when researching **why** a rule exists, how an optimization evolved, or what assumption failed.

The initial corpus comes from complete Git bundles of St4sh, DreamScripts, Starwind Builder, and Rubic0n. Hashes below refer to those repositories. Every receipt is a direct link so a reader or agent can inspect the change instead of manually hunting for it.

## S3ctors S3cret St4sh

| Commit | What it is useful for |
| --- | --- |
| [`4f488e47`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/4f488e4745a52447c526a10bb8c39cc35fb49eb6) | Cod3x parser fast path; less allocation and up to roughly 30% reported improvement |
| [`940fe460`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/940fe46033fd596aef9cbdb17c0057742fb187a0) | Batch-scoped caching of expensive C++/engine-derived condition inputs |
| [`bfe28c01`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/bfe28c012a7c42a8e0349a9b06b5c0962e796c70) | Derived resolver state was not invalidated with its source cache |
| [`b148ee31`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/b148ee31cb8fd023436e8b00d984d1098299b0a2) | Generation/epoch identity for stale deferred work |
| [`c100e5eb`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/c100e5eb90718aaf6df75d00db4f235b568bc13a) | Making corrupted presence collection fatal rather than continuing ambiguously |
| [`e3e21b64`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/e3e21b642728d07de2b0ae7565b7aa4a3e2766d9) | `core.quit()` does not terminate local control flow immediately |
| [`f834f17e`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/f834f17e9bd18837d68faf60b80678bad23aa384) | Real engine content made a supposedly-required pathgrid optional |
| [`3649154c`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/3649154c732e0bfaa87d781ad587fd02aaac1643) | Engine userdata was treated like an ordinary Lua table |
| [`fbe9f127`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/fbe9f127c46161528b9156f9f952ca536c588f6e) | “same playlist” fast path skipped dependent silence/playback state |
| [`8f3e075d`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/8f3e075d98c1fbd31a7a2eecce09cbece7686ff1) | `openmw.types` was incorrectly modeled as available in menu scripts |
| [`c3e70aa5`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/c3e70aa5084e8042817f628cdef1eec7148ca9f7) | Hoisting stable `gameSelf.id` in a combat hot path |
| [`02a00845`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/02a00845e213467106756a9f641a67eb1698c559) | Stabilizing target positions by avoiding repeated bounding-box queries |
| [`de85472b`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/de85472bc40a29076b55e20d7ba0715326f37242) | Lock-on rewrite focused on raycasts/runtime operations rather than Lua cosmetics |
| [`ae7561d`](https://github.com/DreamWeave-MP/Starwind-Builder/commit/ae7561d0b5aa16170059193c21054913cadb6f62) | Physics and rendering raycasts answered different questions |

### Design genealogies

| Commit | What it is useful for |
| --- | --- |
| [`f6f73098`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/f6f73098e6b4039416709bbcf9ecf1512b6a9255) | First internal S3lf wrapper around repeated OpenMW object interpretation |
| [`9ffbd3f9`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/9ffbd3f96923a01675345569cdaebf4934bca77d) | Standalone S3lf release |
| [`257aabfd`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/257aabfdc42e2a483057940e031140eb5d4eaf7a) | Migration of S3lf into H3lp Yours3lf |
| [`cd16c7cc`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/cd16c7ccfbfa9e475caa5cc5781fab54d70c449a) | Named `nullFunction` primitive in H3 |
| [`d40f379c`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/d40f379ce7cae2fc3ba9a1f3f50a5c2431d6ca0b) | S3maphore promotion from swappable handlers to H3 StateMachine |
| [`3b1f8a75`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/3b1f8a75cb84edb65588aaa8b024a5571b4de756) | CamHelper migrated from T4rg3t5 into H3 |
| [`bf230995`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/bf23099565db2e94f3450dbfdadc9c198e204d74) | ImageAtlas added to H3 |
| [`224d20c5`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/224d20c505c64d81b8bf5e4a36b2fa81fc376ae6) | H4ND's first ImageAtlas consumer |
| [`51cfc16c`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/51cfc16c3371eeedaebc94ea81f193cfb767522e) | Dedicated ImageAtlas next-frame operation |
| [`8fa3d40a`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/8fa3d40a879c178d81e06c46bd1a3d3d64fef32e) | ImageAtlas current-tile update fix |
| [`8d8f2025`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/8d8f20252f7b9a535c64c98e37299334a3e25bae) | CamHelper hot-path rewrite |
| [`dcf5bf21`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/dcf5bf214c979272d5938d063b9859dbc1cd7914) | S3maphore's move from update polling to event-driven resolution |
| [`80b31628`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/80b31628948f3a2c4b3c0bd711a2f6130221cda1) | Keeping PlaylistRules cache machinery private |
| [`07df2d73`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/07df2d7356d1331038b44fe67c2c252949147c53) | First caching helper for PlaylistRules |
| [`186e469d`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/186e469dabb02c5fc5ef24d5be09f52ebc506230) | Deploying the caching helper across the rules |
| [`32153de8`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/32153de83e2714c18f6364c94b98d3cc75d0eeb8) | Event-driven clearing of combat-target caches |
| [`a1a431b1`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/a1a431b1b530500d28620fc2147f90512c1ea643) | Per-target cache invalidation while preserving dynamic-stat caching |
| [`73038e4a`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/73038e4ad9e4755ed5c525fa59babb89f48f98ad) | Clearing combat caches when an actor leaves combat |
| [`c077f20f`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/c077f20f251b5b3e1a3b11c16a7529e2bb714073) | Correcting cache clearing at combat start |
| [`e485c601`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/e485c6012da36017499d6819bdbc84d8e80b11ec) | Local track-change handler registration instead of direct internal events |
| [`57eb4b69`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/57eb4b69c0d5568bf82d4b476632cd2ada055a48) | Bounded actor queue for combat scanning |
| [`8cad4c1f`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/8cad4c1fc3590a21afd3b91cfee0b15bf080ed26) | Dynamic frame-time batch sizing experiment |
| [`17cfca78`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/17cfca786c6579d68246ccd21e5beab393ec3362) | Reverting dynamic batch sizing in favor of a fixed bound |
| [`c967a3d2`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/c967a3d20c5fa51b801dab53369e579f9fd08994) | Capped actor scheduler with a target revisit interval |
| [`7cb5a731`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/7cb5a7310a6f0d37036c5a96b12c284f5caf4cd9) | SSS utilities promoted into H3 after duplication was proven |
| [`a9afe80a`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/a9afe80ac47b34e98c590fa55b3ac0c7534335e5) | `isOpenMW` promoted into H3 |
| [`d6a45c62`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/d6a45c6254c817557fa1d2da64fe12c236675cd2) | S3maphore deletion after H3 took ownership of `isOpenMW` |
| [`30ca0dbe`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/30ca0dbe30093e0ab686c56fed5ac0df8c831237) | Dedicated `clear` operation extracted from repeated consumers |
| [`bf0b6505`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/bf0b6505f154ad3b0890405b61bccad9d3afcd21) | H3 `clear` with a Rubic0n fast path and Lua fallback |
| [`7a2580ca`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/7a2580ca2268869e8b0246135894d5ee0bbd65a8) | ProtectedTable checks for adding new values |
| [`94f60f76`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/94f60f766ec7f1c9ea769b9568bd1b63032f4b87) | ProtectedTable diagnostics for failed inputs |
| [`e6b7f1a2`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/e6b7f1a25722bd620cf8557bb0e534fbedefcabb) | ProtectedTable transparently indexes settings |
| [`4d78a2d5`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/4d78a2d594fc7e43c64a8d176111044b9452702e) | ProtectedTable metatable protection |
| [`5cbc5ed6`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/5cbc5ed6e2003a18c9fcc30c6e86e47403e0014a) | ProtectedTable promoted as an interface |
| [`36ef9e14`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/36ef9e14d2ba180befdb99a4a3e99f4d0ad41bbb) | ProtectedTable state made directly readable and writable |
| [`e0122c97`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/e0122c973a0f075918ee12cfddaee0d5caab62cf) | Existing storage sections accepted by ProtectedTable |
| [`5d2ece29`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/5d2ece2920c86ae24c8851bd94859eb1c29f5f23) | Writable storage groups supported by ProtectedTable |
| [`9d5c7c2d`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/9d5c7c2dbb4c566b1b52549d2d0e177758683f38) | More precise cached-setting invalidation |
| [`27c5eb07`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/27c5eb07642d64a33532b4f7e1b3e21f57741999) | Explicitly disabling ProtectedTable subscriptions |
| [`5f051eee`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/5f051eee76be9bc7e682d9436412645ce513ec12) | ProtectedTable hot-path allocation removal |
| [`2499548e`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/2499548e7429102d837dcf8444ee28256a55c9fc) | ProtectedTable lookup optimization |
| [`e6a18a18`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/e6a18a181612ba7e63b2d1197a5e3d803ef3231a) | ProtectedTable optimization and annotation pass |
| [`e3501182`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/e3501182d41bc0d92953a0a9e4508f82cab8757e) | PlaylistRules constructor removed in favor of direct state ownership |
| [`cec95881`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/cec95881e63e6439564548d4d40dc2183b97e596) | Removing an unnecessary S3maphore constructor/object boundary |
| [`382df1e0`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/382df1e03077ab2d5ea9f71d5bbff7120d112ed5) | Flattening CellPresence into PlaylistState |
| [`76358648`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/76358648d8f0f7e03fcca055c9cfa8ac83e3fd86) | Removing the redundant `staticList` representation |
| [`b202141c`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/b202141c0eb3d9617ed55f73b80485fc9c9fc574) | Adding per-cell presence scope |
| [`8d574d40`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/8d574d403613a184bbf47adec238d7a16eed4e22) | Coroutine-driven global presence sweep |
| [`d7f38bb5`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/d7f38bb5b983c5e26d28fbd23c88a8ce38a3c6ff) | Large StaticCollection optimization pass |
| [`342d77dd`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/342d77dd6f012caa29458a3623499aacceff63f9) | Event-driven cell and combat-target tracking |
| [`5d608a26`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/5d608a26a3a5496757d37284686461b44c606081) | StaticCollection switched to cached string primitives |
| [`5b1537b5`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/5b1537b504e2861755d1bb4f63ac5c5d1362dbd8) | Sorting playlists at load time for deterministic resolution |

## DreamScripts

| Commit | What it is useful for |
| --- | --- |
| [`219c6e4b`](https://github.com/DreamWeave-MP/DreamScripts/commit/219c6e4b6b2567d7950f20368b2c765c654dd789) | Legitimate protected execution at an arbitrary script/host boundary |
| [`28062542`](https://github.com/DreamWeave-MP/DreamScripts/commit/28062542ca4e8f0eecc65237264aa2b13c44e8d1) | Cache the loaded module value rather than an intermediate compiled chunk |
| [`046694b6`](https://github.com/DreamWeave-MP/DreamScripts/commit/046694b61cb870994d89ac786131d7a1af3a13a3) | Centralize stale event-registration cleanup at the load/reload lifecycle boundary |
| [`c8737a3`](https://github.com/DreamWeave-MP/DreamScripts/commit/c8737a31b9af36d70320bec8dc38ea0c906bfba6) | A protected error path that failed to print the traceback |
| [`0e7eb8d`](https://github.com/DreamWeave-MP/DreamScripts/commit/0e7eb8d3906af34abaa628fa338672ebc8deb75a) | The same lesson, learned loudly enough to deserve a second receipt |
| [`3523eaf`](https://github.com/DreamWeave-MP/DreamScripts/commit/3523eaf7cc14eed0ffe4f3156ba23751e8f32a5f) | Hypothesis: numeric GMSTs may not need conversion |
| [`39ba4b1`](https://github.com/DreamWeave-MP/DreamScripts/commit/39ba4b14f837e504ad9a3cbc370a4fc73c926259) | Immediate revert when that hypothesis broke behavior |
| [`1e3bbc4`](https://github.com/DreamWeave-MP/DreamScripts/commit/1e3bbc42ed1b806a51cd43250d0d9e202825d43f) | Actual finding: the relevant GMST values arrived as userdata |
| [`1db40db`](https://github.com/DreamWeave-MP/DreamScripts/commit/1db40dbe9c9670ecd9723aa07ff578f368f65640) | Initial FFI-string optimization experiment |
| [`b575991`](https://github.com/DreamWeave-MP/DreamScripts/commit/b5759916ca9b8813f6b83594d454d37e8299d7d0), [`7ef025c`](https://github.com/DreamWeave-MP/DreamScripts/commit/7ef025c1a3dcf386fbece91fad26b222d21db88f), [`d171ef4`](https://github.com/DreamWeave-MP/DreamScripts/commit/d171ef4b4652a79ffa1e149a438eaf00483f2feb) | Reverting the FFI-string experiment while isolating the failure |
| [`9f569d0`](https://github.com/DreamWeave-MP/DreamScripts/commit/9f569d0848b191b8a101b6c884f6cc57e5166e23) | Finding that the strings were not the actual bug; an argument was |
| [`ad910b8`](https://github.com/DreamWeave-MP/DreamScripts/commit/ad910b8b13620cf1437bb7457581a252b4a82a41) | Reapplying the mechanism after the real failure was understood |

## Starwind Builder

| Commit | What it is useful for |
| --- | --- |
| [`a3c598b`](https://github.com/DreamWeave-MP/Starwind-Builder/commit/a3c598bd321d62ec044bc1e61f8c4c730fcd7c91) | Historical runtime context probing helper based on failed `require` calls |
| [`fe57c24`](https://github.com/DreamWeave-MP/Starwind-Builder/commit/fe57c2459f1d947ba659b989f4dbf646cd1798a7) | Introduction of the `protectedTable` abstraction from earlier CHIM work |
| [`8d83601`](https://github.com/DreamWeave-MP/Starwind-Builder/commit/8d83601d3fc4758864f9d48a273703f159936eb) | Adding caching to the magic storage/proxy surface |
| [`1d12418`](https://github.com/DreamWeave-MP/Starwind-Builder/commit/1d12418fbef01fde5cfc17849934eedfaab0cd91) | Expanding the proxy into a shared manager interface |
| [`25c3661`](https://github.com/DreamWeave-MP/Starwind-Builder/commit/25c366122db8c0d96a861104b18eb47e9ebec460) | Shadow cache invalidation broke when subscription behavior was overridden |
| [`2b94a9f`](https://github.com/DreamWeave-MP/Starwind-Builder/commit/2b94a9faf0e5f2ad1ec79695250015255f7976a5) | Initial lock-on/camera manager architecture |
| [`f90baec`](https://github.com/DreamWeave-MP/Starwind-Builder/commit/f90baec9f50a7fab7bb5a731a0986e71dee4c53e) | Lock-on texture accidentally recreated continuously |

Starwind is particularly useful because many ideas later found cleaner forms in H3 or current St4sh code. Treat it as evolutionary evidence, not current doctrine.

## Rubic0n

Rubic0n includes substantial LuaJIT/OpenResty upstream history. The commits below are selected because they illuminate DreamWeave runtime investigation relevant to OpenMW workloads.

| Commit | What it is useful for |
| --- | --- |
| [`7737682e`](https://github.com/DreamWeave-MP/Rubic0n/commit/7737682e1324e263fa261aacd3c03c8c5650dc25) | Optional GC telemetry counters |
| [`c50281e9`](https://github.com/DreamWeave-MP/Rubic0n/commit/c50281e94da7b03fe6f36356539f854d87910fa2) | GC allocation telemetry expansion |
| [`aa5a699f`](https://github.com/DreamWeave-MP/Rubic0n/commit/aa5a699fb1095d557909d83a1b46107f080ed61c) | Exact-size userdata allocation cache experiment |
| [`b57f7756`](https://github.com/DreamWeave-MP/Rubic0n/commit/b57f77568e5895a1e3f5bc1f83448d9989f098d2) | Userdata finalizer lookup cache experiment |
| [`edb8fe9c`](https://github.com/DreamWeave-MP/Rubic0n/commit/edb8fe9cda93fa242b891efdad5fda92ca9b4254) | Wholesale revert of the userdata-cache experiments |
| [`d1e1a8fc`](https://github.com/DreamWeave-MP/Rubic0n/commit/d1e1a8fc4876a19c10332dfa9d71f0d4318efe3e) | Direct C userdata finalizer path |
| [`3f9e260c`](https://github.com/DreamWeave-MP/Rubic0n/commit/3f9e260c18de0c7edbe420f043c6410d6a0968c2) | Non-resurrecting C finalizer mode |
| [`36a21256`](https://github.com/DreamWeave-MP/Rubic0n/commit/36a212565dc358620ae4f6133252011bd5ceeaa0) | GC pacing tuned for OpenMW-style userdata churn |
| [`c7f2c204`](https://github.com/DreamWeave-MP/Rubic0n/commit/c7f2c204fa4d6a70f7f3b2cd0d53e88e48c82935) | Gated batched direct C finalizers |
| [`6797075e`](https://github.com/DreamWeave-MP/Rubic0n/commit/6797075e4b1215c6b3782cb68fa7958dbe4fb13f) | Fixing GC accounting for batched finalizers |
| [`75a9a247`](https://github.com/DreamWeave-MP/Rubic0n/commit/75a9a2473f56adee36590e4480f031451383cae6) | Pacing batched finalizers by GC budget |
| [`8e6520a7`](https://github.com/DreamWeave-MP/Rubic0n/commit/8e6520a7aecd0517e792b359afbbfd7274791f5f) | Optional PC position from `jit.util.tracesnap()` for trace analysis |
| [`6c23f555`](https://github.com/DreamWeave-MP/Rubic0n/commit/6c23f555085aa62922aa1394787953b00d55ff16) | Making the sandbox bypass an explicit opt-in build facility |
| [`a04b64a5`](https://github.com/DreamWeave-MP/Rubic0n/commit/a04b64a52962f559e8799e585d8b1a85b7502ded) | Experimental paged allocator front end |
| [`8acb8986`](https://github.com/DreamWeave-MP/Rubic0n/commit/8acb898669d0567835b0d0686607972ef4a72c87) | Vector-userdata allocation harnesses |

## How to use this index

When a Cod3x rule feels oddly specific, do not merely repeat the rule.

Open the relevant commit and ask:

1. what the old code believed;
2. what runtime/engine behavior contradicted it;
3. whether the fix changed correctness, performance, or both;
4. whether the lesson still applies to current OpenMW;
5. whether a newer implementation refined the lesson again.

The point of history is not authority.

The point is **reproducible context**.
