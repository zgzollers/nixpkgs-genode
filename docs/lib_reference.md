# Types
## Genode Tree
A Nix attribute set representing the Genode source tree and dependencies required to use its corresponding build system. The set contains the following attributes.

| Attribute | Type | Description|
|---|---|---|
| toolchain | `package` or `path` | Genode toolchain appropriate for use in with this particular source tree |
| buildInputs | `list of packages` | Build dependencies required to use tools and build artifacts contained in the `src` attribute |
| src | `path` | Patched Genode source code with optionally prepared ports and extra repos |


## Genode Repo
A Nix attribute set representing a Genode repo. The set contains the following attributes.

| Attribute | Type | Description|
|---|---|---|
| name | `str` | Name of the repo as it will appear in the Genode tree |
| src | `path` | Source code for the repo |

## Genode Port
| Attribute | Type | Description|
|---|---|---|
| name | `str` | Name of the port as it appears in its corresponding `*.port` file name |
| type | `str` | Type of the files that need to be fetched for the port (i.e., `git` or `archive`) |
| extraInputs | `list of packages` | Extra dependencies required to prepare and/or build the port |
| src | `path` | Final artifacts of the prepared port

# Functions
## mkGenodeBase
Creates a [`genode-tree`][1] using a specific commit/version of the Genode source code. In particular, it patches shell script shebangs and initializes the list of dependencies and toolchain. It is recommended that this function is used to construct the initial tree rather than manually creating the attribute set to ensure all necessary fixes are applied. 

| Parameter | Default | Description |
|---|---|---|
| src | none | Raw Genode source code usually obtained from a flake input or `builtins.fetchGit` |
| toolchain | none | Genode toolchain package to use with this version of the source tree |
| extraInputs | `[ ]` | Extra dependencies to be added to the `buildInputs` attribute of the resulting [`genode-tree`][1] |

## mkGenodeTree
Expands an existing [`genode-tree`][1] to include additional [`genode-ports`][3] and [`genode-repos`][2]. It expects a tree that was originally derived from a [`mkGenodeBase`](#mkgenodebase) call. That is, it expects the base set of dependencies to be present and all shell scripts to be patched.

| Parameter | Default | Description |
|---|---|---|
| genodeTree | none | Existing tree to be expanded |
| repos | `[ ]` | Additional [`genode-repos`][2] to be added to the tree |
| ports | `[ ]` | Additional [`genode-ports`][3] to be added to the tree | 

## mkGenodeRepo
Creates a [`genode-repo`][2] that can be added to an existing [`genode-tree`][1].

| Parameter | Default | Description |
|---|---|---|
| src | none | Raw source files for the repo |
| name | none | Name of the repo as it will appear in the `repos` directory of a [`genode-tree`][1]

## mkGenodeDerivation
A convenience function that allows expanding the Genode tree, creating a build directory, and setting necessary environment variables for running build commands. This function may be used to produce artifacts from the Genode build system as Nix derivations. In most situations, this is the only function needed.

| Parameter | Default | Description |
|---|---|---|
| name | none | Name of the derivation |
| genodeTree | none | [`genode-tree`][1] containing to the source code and necessary dependencies to build the derivation
| repos | `[ ]` | List of arguments that will be passed through[`mkGenodeRepo`](#mkgenoderepo), adding the resulting [`genode-repo`][2]'s to the `genodeTree` before building the derivation |
| ports | `[ ]` | List of arguments that will be passed through the [`preparePort`](#prepareport), adding the resulting [`genode-port`][3]'s to the `genodeTree` before building the derivation | 
| buildConf | [default.conf](../lib/build/default.conf) | File used to replace the default `etc/build.conf` file in the Genode build directory |
| extraInputs | `[ ]` | Extra build inputs to be added when building the derivation |
| buildPhase | none | Build commands executed from inside a Genode build directory (see below for environment variables set before calling this phase) |
| installPhase | none | Similar to `installPhase` parameter for `mkDerivation`. Commands executed outside the build directory (use `$BUILD_DIR` to access build artifacts) |

### Shell Environment
During the `buildPhase` and `installPhase`, the following environment variables are made available.

| Variable | Default Value | Purpose |
|---|---|---|
| `SOURCE_DIR` | `"$(pwd)/./.build"` | The working directory for the build steps |
| `GENODE_DIR` | `"${SOURCE_DIR}/genode-src"` | The location of the root of the working copy of the Genode source tree |
| `BUILD_DIR` | `"${SOURCE_DIR}/build"` | The location of the Genode build directory |

## fetchPort
Fetch required files for a [`genode port`](#genode-port). This function is not intended to be called manually. Use [`preparePort`](#prepareport) instead.

## preparePort
Create a [`genode port`](#genode-port) that is ready to be merged into a Genode tree and used in the build system. Note that this is the only way to prepare ports for a Nix derivation as the `prepare_port` utility cannot access the internet in `mkGenodeDerivation`.

| Parameter | Default | Description |
|---|---|---|
| genodeTree | none | [`genode-tree`][1] containing the `*.port` file to be prepared (these files are located in the `ports` directory of a [`genode-repo`][2]) |
| name | none | Name of the port as it appears in the port file name (`${NAME}.port`) |
| type | none | Type of the port to be prepared. This is used for determining how to fetch files with Nix (either git or archive). The correct value may be determined be the `DOWNLOADS` variable in the `*.port` file |
| hash | none | Hash of the port. Can be determined by the string stored in the corresponding `*.hash` file |
| url | none | URL of the source code or archive. Can be obtained from the `URL` variable in the `*.port` file |
| extraInputs | `[ ]` | Extra dependencies required to prepare/build the port. Added to the `buildInputs` attribute of a [`genode-tree`][1] when passed to the [`mkGenodeTree`](#mkgenodetree) function |
| rev | `null` | Git commit hash to be used when pulling the port source repository. Can be obtained from the `REV` variable in the `*.port` file. *Only required if port is of type `git`* |
| dir | `null` | Relative location of the source code. Can be obtained from the `DIR` variable in the `*.port` file. *Only required if the port is of type `git`* 
| sha256 | `null` | Expected SHA256 hash of a downloaded archive. Can be obtained from the `SHA` variable in the `*.port` file. *Only required if port is of type `archive`* 




[1]: #genode-tree
[2]: #genode-repo
[3]: #genode-port