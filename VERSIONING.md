# Versioning Strategy

This repository follows semantic versioning (semver) as required by the Dev Container Template specification.

## Template Versioning

Each template has its own version in its `devcontainer-template.json` file:

```json
{
  "id": "template-name",
  "version": "1.2.3",
  ...
}
```

### Version Format

We use semantic versioning: `MAJOR.MINOR.PATCH`

- **MAJOR**: Breaking changes (incompatible API changes)
- **MINOR**: New functionality (backwards compatible)
- **PATCH**: Bug fixes (backwards compatible)

## CI/CD Versioning Behavior

### Pull Request Builds

PR builds create prerelease versions for testing:

- **Templates**: `0.0.0-pr.<PR_NUMBER>` (e.g., `0.0.0-pr.42`)
- **Docker Images**: `pr-<PR_NUMBER>` (e.g., `pr-42`)

These versions are overwritten on each PR update.

### Main Branch Builds

When changes are merged to main, the CI publishes with proper semantic versioning:

#### Templates (OCI Artifacts)
The devcontainer CLI automatically creates multiple tags:
- `1.2.3` - Full version
- `1.2` - Minor version (points to latest patch)
- `1` - Major version (points to latest minor)
- `latest` - Always points to newest version

#### Docker Images
Similar tagging strategy:
- `1.2.3` - Full version
- `1.2` - Minor version
- `1` - Major version
- `latest` - Always points to newest version

## Version Bumping

To release a new version:

1. Update the `version` field in `src/<template>/devcontainer-template.json`
2. Commit the change
3. Create a PR
4. After merge, the CI will automatically publish with the new version

### When to Bump Versions

#### Patch Version (1.0.0 → 1.0.1)
- Bug fixes in scripts
- Security updates that don't change functionality
- Documentation fixes

#### Minor Version (1.0.0 → 1.1.0)
- New features or tools added
- New configuration options
- Non-breaking improvements

#### Major Version (1.0.0 → 2.0.0)
- Breaking changes to configuration
- Removal of features
- Changes requiring user action to upgrade

## Testing PR Versions

During PR review, you can test the PR artifacts:

```bash
# Test the template
devcontainer templates apply \
  --template-id ghcr.io/liquescent-development/templates/liquescent-devcontainer:0.0.0-pr.42

# Use the Docker image directly
docker pull ghcr.io/liquescent-development/liquescent-devcontainer:pr-42
```

## Version History

The semver tagging strategy ensures that:
- Users can pin to specific versions
- Major/minor tags automatically update to latest patch
- Previous versions remain available
- `latest` always points to the newest stable version

## Multiple Templates

Each template in `src/` maintains its own version independently. This allows:
- Different templates to evolve at different rates
- Breaking changes in one template don't affect others
- Users can mix and match template versions