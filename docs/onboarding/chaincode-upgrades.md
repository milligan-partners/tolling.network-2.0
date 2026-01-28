# Chaincode Upgrade Procedures

This guide covers how to safely upgrade chaincode on the Tolling.Network Hyperledger Fabric 2.5.x network.

## Overview

Hyperledger Fabric 2.x uses a decentralized chaincode lifecycle where:

1. **Sequence numbers** track chaincode versions (not the version string)
2. **Organizations must approve** before a new definition can be committed
3. **State data persists** automatically through upgrades
4. **Rollback** is achieved by deploying old code with a new sequence number

### Key Concepts

| Concept | Description |
|---------|-------------|
| **Version** | Human-readable identifier (e.g., "1.0", "1.1") |
| **Sequence** | Integer that must increment for every upgrade (starts at 1) |
| **Package ID** | Hash of the chaincode package, unique per version |
| **Approval** | Each org approves the chaincode definition before commit |
| **Commit** | Makes the new definition active on the channel |

## Prerequisites

Before upgrading chaincode:

1. **Network running**: Docker Compose or Kubernetes cluster active
2. **Chaincode deployed**: Initial deployment completed via `deploy-chaincode.sh`
3. **Peer CLI available**: `peer` binary in PATH
4. **Crypto material**: `network-config/crypto-config/` populated
5. **Code tested**: New chaincode version passes all unit tests

## Upgrade Script

The primary upgrade tool is `scripts/upgrade-chaincode.sh`.

### Usage

```bash
./scripts/upgrade-chaincode.sh [OPTIONS]

Options:
  -h, --help              Show this help message
  -n, --name NAME         Chaincode name (default: niop)
  -v, --version VERSION   New chaincode version (required for code upgrades)
  -c, --channel NAME      Channel name (default: tolling)
  -p, --path PATH         Chaincode source path
  --policy-only           Only update endorsement policy (no code change)
  --dry-run               Preview upgrade without executing
  --force                 Skip confirmation prompts
  --verbose               Enable verbose output
```

### Examples

#### Standard Code Upgrade

```bash
# Upgrade niop chaincode to version 1.1
./scripts/upgrade-chaincode.sh -n niop -v 1.1 -p chaincode/niop
```

#### Preview Upgrade (Dry Run)

```bash
# See what would happen without making changes
./scripts/upgrade-chaincode.sh -n niop -v 1.1 --dry-run
```

#### Policy-Only Upgrade

```bash
# Update endorsement policy without changing code
./scripts/upgrade-chaincode.sh -n niop --policy-only
```

#### Force Upgrade (No Prompts)

```bash
# Skip confirmation (for CI/CD pipelines)
./scripts/upgrade-chaincode.sh -n niop -v 1.1 --force
```

### What the Script Does

1. **Queries current state**: Gets deployed version and sequence number
2. **Auto-increments sequence**: Calculates next sequence number
3. **Shows upgrade plan**: Displays before/after comparison
4. **Confirms with user**: Unless `--force` is specified
5. **Packages chaincode**: Creates new `.tar.gz` package
6. **Installs on all peers**: Installs package on each peer
7. **Approves for all orgs**: Each org approves the new definition
8. **Checks commit readiness**: Verifies all approvals received
9. **Commits definition**: Activates the new chaincode
10. **Verifies upgrade**: Confirms new version is active

## Rollback Procedure

If an upgrade causes issues, use `scripts/rollback-chaincode.sh` to revert.

### Important: Forward-Only Rollback

Fabric 2.x doesn't support true rollback. Instead, rollback works by:
- Deploying the **previous code** with a **new (higher) sequence number**
- This is effectively an "upgrade to old code"

State data is preserved through the rollback.

### Usage

```bash
./scripts/rollback-chaincode.sh [OPTIONS]

Options:
  -h, --help              Show this help message
  -n, --name NAME         Chaincode name (default: niop)
  -v, --version VERSION   Target version to roll back to (required)
  -t, --tag TAG           Git tag to checkout (e.g., v1.0.0)
  -p, --path PATH         Path to previous chaincode source
  -c, --channel NAME      Channel name (default: tolling)
  --dry-run               Preview rollback without executing
  --force                 Skip confirmation prompts
  --verbose               Enable verbose output
```

### Examples

#### Rollback Using Git Tag

```bash
# Roll back to version 1.0 using git tag v1.0.0
./scripts/rollback-chaincode.sh -n niop -v 1.0 -t v1.0.0
```

#### Rollback Using Source Path

```bash
# Roll back using a specific source directory
./scripts/rollback-chaincode.sh -n niop -v 1.0 -p /path/to/old/chaincode
```

#### Preview Rollback

```bash
# See what would happen without making changes
./scripts/rollback-chaincode.sh -n niop -v 1.0 -t v1.0.0 --dry-run
```

### Version Control Best Practices

To enable reliable rollbacks:

1. **Tag every production release**:
   ```bash
   git tag -a v1.0.0 -m "Chaincode version 1.0 release"
   git push origin v1.0.0
   ```

2. **Use consistent naming**: `v{version}` or `chaincode-{version}`

3. **Keep release branches**: For major versions, maintain release branches

## Makefile Targets

Common operations are available via Make:

```bash
# Upgrade chaincode (interactive)
make chaincode-upgrade

# Check current chaincode status
make chaincode-status

# Rollback chaincode (requires VERSION and TAG)
make chaincode-rollback VERSION=1.0 TAG=v1.0.0
```

## Zero-Downtime Upgrades

The Fabric lifecycle provides zero-downtime upgrades through its consensus mechanism:

1. **During install phase**: New code is installed but not active
2. **During approval phase**: Orgs approve at their own pace
3. **At commit**: New code becomes active atomically
4. **Existing transactions**: Complete under old code
5. **New transactions**: Use new code immediately after commit

### Best Practices

1. **Test thoroughly**: Run integration tests against new code
2. **Stage the upgrade**: Install and approve during low-traffic periods
3. **Commit quickly**: Minimize time between approvals and commit
4. **Monitor closely**: Watch logs for errors after commit

## State Data Persistence

State data (world state in CouchDB) persists automatically through upgrades:

- **No migration needed** for schema-compatible changes
- **Keys remain intact**: All state keys are preserved
- **Private data preserved**: PDC data also persists

### Schema Changes

If your upgrade changes the data schema:

1. **Additive changes**: Add new fields with defaults - safe
2. **Removing fields**: Code should ignore extra fields - usually safe
3. **Renaming fields**: Requires migration logic in chaincode
4. **Type changes**: Requires careful migration handling

For complex migrations, implement migration logic in the chaincode `Init` function.

## Troubleshooting

### Upgrade Fails at Approval

```
Error: failed to endorse chaincode: endorsement failure during invoke
```

**Cause**: Peer may not have the package installed.

**Fix**: Verify installation:
```bash
peer lifecycle chaincode queryinstalled
```

### Commit Fails - Not All Orgs Approved

```
Error: chaincode definition not agreed to by enough organizations
```

**Cause**: Some organizations haven't approved the definition.

**Fix**: Check readiness:
```bash
peer lifecycle chaincode checkcommitreadiness \
  --channelID tolling --name niop --version 1.1 --sequence 2 --output json
```

### Package ID Mismatch

```
Error: existing definition has different package ID
```

**Cause**: Different code was packaged than expected.

**Fix**: Ensure all orgs use the same source code and packaging process.

### Sequence Number Conflict

```
Error: sequence must be greater than current sequence
```

**Cause**: Attempting to use a sequence number that's already been used.

**Fix**: The script auto-increments sequence. If running manually, query current:
```bash
peer lifecycle chaincode querycommitted --channelID tolling --name niop
```

## Security Considerations

1. **Review all code changes**: Chaincode runs on all peers
2. **Verify package hashes**: Ensure all orgs have identical packages
3. **Coordinate upgrades**: All orgs should be aware of upgrade timing
4. **Test endorsement policies**: Verify policies work as expected
5. **Backup state**: While state persists, have CouchDB backups
6. **Rollback plan ready**: Always know how to roll back before upgrading

## Related Documentation

- [Deployment Guide](deployment.md)
- [Testing Guide](testing.md)
- [Hyperledger Fabric Chaincode Lifecycle](https://hyperledger-fabric.readthedocs.io/en/latest/chaincode_lifecycle.html)
