# GitHub Organization Migration

**Date:** 2026-01-11
**From:** awilkinson (personal account)
**To:** Folly-Partners (organization)

## Migration Completed

All repositories have been migrated from the personal GitHub account (`awilkinson`) to the Folly-Partners organization. The migration was completed successfully on 2026-01-11.

## Migrated Repositories

The following 12 repositories are now under Folly-Partners:

1. **claude-code-sync** (was: `~/.claude`)
   New URL: `https://github.com/Folly-Partners/claude-code-sync.git`

2. **Journal**
   New URL: `https://github.com/Folly-Partners/Journal.git`

3. **tiny-investors-lovable**
   New URL: `https://github.com/Folly-Partners/tiny-investors-lovable.git`

4. **SuperThings**
   New URL: `https://github.com/Folly-Partners/SuperThings.git`

5. **deep-background**
   New URL: `https://github.com/Folly-Partners/deep-background.git`

6. **email-triage**
   New URL: `https://github.com/Folly-Partners/email-triage.git`

7. **ThingsTodayPanel**
   New URL: `https://github.com/Folly-Partners/ThingsTodayPanel.git`

8. **tiny-investors**
   New URL: `https://github.com/Folly-Partners/tiny-investors.git`

9. **Dealhunter**
   New URL: `https://github.com/Folly-Partners/Dealhunter.git`

10. **company-analyzer** (shares Dealhunter repo)
    New URL: `https://github.com/Folly-Partners/Dealhunter.git`

11. **Overstory**
    New URL: `https://github.com/Folly-Partners/Overstory.git`

12. **Deep-Personality**
    New URL: `https://github.com/Folly-Partners/Deep-Personality.git`

## Migration Scripts

Two scripts are available for migration:

- **`scripts/validate-repos-for-migration.sh`** - Check which repos need migration
- **`scripts/migrate-all-repos-to-folly.sh`** - Perform the migration

## For Other Macs

When you next use another Mac, run the migration:

```bash
cd ~/.claude
git pull origin main
./scripts/migrate-all-repos-to-folly.sh
```

The script will:
1. Check which repos still point to the old organization
2. Prompt for confirmation
3. Update remote URLs for all repos
4. Validate connectivity
5. Show success/failure summary

## Rollback Instructions

If you need to rollback a specific repository:

```bash
cd /path/to/repo
git remote set-url origin https://github.com/awilkinson/repo-name.git
git fetch origin
```

For all repositories:

```bash
~/.claude/scripts/migrate-all-repos-to-folly.sh --rollback
```

(Note: `--rollback` flag not yet implemented - use manual rollback above)

## Verification

To verify all repos are migrated:

```bash
~/.claude/scripts/validate-repos-for-migration.sh
```

All repos should show "Already migrated to Folly-Partners".

## Notes

- The migration only changes git remote URLs
- Uncommitted changes and working tree are unaffected
- Launch agent and sync automation continue working
- GitHub redirects may temporarily work but will eventually stop
