# Bellum Gero World Builder - Multi-Project Structural Publishing

The structural production build is desired-state based. Never use a previously generated World Builder TRE as a future build input.

## Permanent inputs

- A clean Bellum Gero `bg_custom1` base TRE containing normal custom content but no `object/building/worldbuilder/` or `interiorlayout/worldbuilder/` paths and no snapshot OIDs in `0x60000000-0x6FFFFFFF`.
- Independent WBP V2 project files under `MMOCoreORB/bin/worldbuilder/projects/`.
- `worldbuilder_publish_set.json`, which identifies the approved projects that belong in the final TRE.
- `worldbuilder_oid_registry.json`, which permanently maps project logical keys to structural OIDs.
- `worldbuilder_deployed_state.json`, which records the last successfully deployed project fingerprints.

## Candidate build

Run from the repository root:

```bash
python MMOCoreORB/tools/worldbuilder/bellum_worldbuilder.py bake-set \
  --config MMOCoreORB/tools/worldbuilder/worldbuilder_config.json
```

The command always starts from the configured clean base and writes only to the configured candidate directory. It produces:

- `bg_custom1.tre`
- `generated_templates.lua`
- `worldbuilder_publish.json`
- `worldbuilder_ids.json`
- `worldbuilder_oid_registry.json`

`bake-set` never changes the active server/client TRE, active generated Lua, active OID registry, or deployed-state file.

## Add a project

Add one enabled entry to `worldbuilder_publish_set.json`:

```json
{
  "id": "project_b",
  "file": "../projects/project_b.wbp",
  "enabled": true
}
```

Publish IDs are permanent production identities. Use lowercase letters, numbers, and underscores only. Do not casually rename an ID after a project is live.

Adding a project allocates new OIDs below all historical assignments. Existing projects retain their exact OIDs.

## Update a project

Edit its WBP normally, save it, and run `bake-set` again. Existing logical objects retain their OIDs. New local objects/cells receive new OIDs. Removed logical keys become retired and are never assigned to a different key.

If the production fingerprint changed, the candidate manifest lists the project under `refresh_required`.

## Remove a project

Remove or disable its publish-set entry and run `bake-set`. The candidate is rebuilt from the clean base without that project's snapshot nodes, IFFs, ILFs, or Lua registrations. Its historical OID assignments remain in the registry as retired keys.

Before deploying the candidate, run the listed `refreshpublished` commands while the OLD TRE is still active.

## Safe refresh and deployment

For every project listed under `refresh_required`, travel to the listed old planet and run:

```text
/wb refreshpublished <project_id>
/wb refreshpublished <project_id> confirm
```

Only after every required confirm succeeds:

1. Shut Core3 down normally.
2. Deploy the already validated candidate:

```bash
python MMOCoreORB/tools/worldbuilder/bellum_worldbuilder.py deploy-set \
  --config MMOCoreORB/tools/worldbuilder/worldbuilder_config.json \
  --confirm-refreshed
```

`deploy-set` stages every destination first, creates backups, then promotes the same candidate TRE to both client and server together with the matching generated Lua, OID registry, and deployed-state file. It verifies hashes after promotion and attempts rollback if promotion fails.

For an add-only candidate, `--confirm-refreshed` is not required because no old World Builder persistence needs to be removed.

## Important base-TRE rule

The clean base must not be the same path as the active server TRE. Once World Builder content is deployed, the active `bg_custom1.tre` contains published projects and is no longer a valid clean build input.

Keep a separate clean copy such as:

```text
/home/misemerfg/localswgserver/trefiles/bg_custom1_worldbuilder_base.tre
```

Whenever normal Bellum Gero TRE content changes, update this clean base from a known non-World-Builder TRE before rebuilding the World Builder candidate.

## Source-control rule

The OID registry and deployed-state JSON are production state. Back them up and commit their post-deployment changes with the corresponding World Builder work. Losing the registry after projects are live is treated as an error because silently reallocating structural OIDs would be unsafe.
