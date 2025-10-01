# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This repository contains reusable GitHub Actions for Maven-based Java projects, primarily focused on release automation and CI/CD workflows. The actions are published under `emergentdotorg/github-actions` and are used by referencing specific versions (e.g., `@v3`).

## Architecture

### Core Components

**Composite Actions** (located in subdirectories):
- `maven-release/` - Unified release workflow that selects between GitVer-based and classic releases
- `semver-maven-release/` - Semantic versioning-based Maven releases using custom `semtag` tool
- `maven-release-classic/` - Traditional Maven release using `mvn release:prepare release:perform`
- `maven-verify/` - Verification and testing action
- `setup-java-env/` - Java environment setup with multi-version support
- `git-init-user/` - Git user configuration helper
- `tag-release/` - Git tag management for releases
- `build-helper/` - Docker-based action for delivering resources to workspace
- `dump-context/` - Debug utility for displaying GitHub context

**Reusable Workflows** (in `.github/workflows/`):
- `maven-release.yaml` - Main reusable workflow that orchestrates releases
- `maven-verify.yaml` - Reusable verification workflow
- `tag-release.yaml` - Workflow for tagging releases on PR merge

### Release Strategy

The repository supports two release approaches:

1. **GitVer-based releases** - Uses the `git-versioner-maven-plugin` to manage versions based on git state. The workflow detects GitVer by checking for the `gitver.version` property.

2. **Classic Maven releases** - Uses standard Maven Release Plugin with `release:prepare` and `release:perform`.

The `maven-release.yaml` reusable workflow automatically selects the appropriate strategy by:
- Checking if `gitver.version` property is defined in the project
- Routing to `semver-maven-release@v3` if GitVer is present
- Routing to `maven-release-classic@v3` if GitVer is not present

### Key Utilities

**`semver-maven-release/include.sh`**:
- `getReleaseVersion()` - Determines next semantic version using the `semtag` tool
- `setVersionTag()` - Creates version tags
- `calcJavaVers()` - Generates list of JDK versions to install (8, 11, 17, 21 up to specified version)

**`semtag`** - Custom bash script for semantic version tagging based on git history and conventional commits

## Common Development Tasks

### Testing Actions Locally

For Docker-based actions (like `build-helper`):
```bash
docker build -t emergentdotorg/maven-release-action .
docker run --env INPUT_RESOURCES_DEST="foo" emergentdotorg/maven-release-action
```

### Versioning and Releases

This repository uses semantic versioning with automatic tagging on PR merges to main. The `tag-release.yaml` workflow automatically:
1. Tags merged PRs with the next semantic version
2. Optionally syncs major version tags (e.g., `v3` points to latest `v3.x.y`)

### Maven Settings and Toolchains

Actions use custom `settings.xml` files located in each action directory. These files configure:
- Server authentication via environment variables
- GPG signing configuration
- Repository locations

The `setup-java-env` action generates toolchains for multi-version Java support.

## Workflow Input Parameters

### Secrets Required for Maven Releases

Projects consuming these actions typically need:
- `maven_gpg_key` - GPG private key for artifact signing
- `maven_gpg_passphrase` - Passphrase for GPG key
- `deploy_central_actor` / `deploy_central_token` - Maven Central credentials
- `deploy_emergent_nexus_actor` / `deploy_emergent_nexus_token` - Nexus credentials
- `emergentbot_deploy_token` - Token for GitHub package registry

### Common Inputs

**For release actions**:
- `java-version` - JDK version to build with (default: 17)
- `deploy-server` - Maven distribution management server-id (e.g., `central`, `github`, `emergent-nexus`)
- `maven-profiles` - Comma or space-delimited list of Maven profiles to activate
- `maven-version` - Maven version to use (default: 3.9.9)
- `tag-prefix` - Git tag prefix (default: `v`)
- `dry-run` - Perform dry run without actual deployment

## Important Notes

- All actions set up Git user config as `github-actions[bot]`
- Maven operations use `-B` (batch mode), `-ntp` (no transfer progress), `-e` (show errors)
- The repository uses `stCarolas/setup-maven@v5` for Maven installation
- Actions use `actions/setup-java@v4` with Temurin distribution
- Git operations use `--follow-tags --atomic` for pushing to ensure consistency