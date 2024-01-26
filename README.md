# Genode Nixpkgs
This repository provides useful Nix flakes/packages for developing and building systems based on the [Genode OS Framework](https://genode.org). Some familiarity with Nix (flakes) is recommended.

# Usage
The following sections assume a working Nix installation with flakes enabled. See the official [documentation](https://nixos.wiki/wiki/Flakes) for instructions for enabling Nix flakes.

## Flake Template
To clone the provided flake template and create a new Genode project, run the following command.

```console
nix flake new -t github:zgzollers/nixpkgs-genode#genode ./genode-project
```

Nix flakes can only access files that are added to a git repository. To initialize a new repository in the flake directory, run

```console
git init && git add .
```

Make any desired changes to the initial template, then create the initial flake lock file by running

```console
nix flake update && git add flake.lock
```

Finally, commit the changes. For some yet-unclear reason, the Genode build system will fail to build/run system scenarios and components if the initial flake template (in particular the `.gitignore`) is not committed to the repository.

```console
git commit -m "Initial commit"
```

Note that in order for Nix flakes to access a source file, it must be tracked by (not necessarily committed to) the repository containing the flake. It is good practice to run `git add .` before attempting to rebuild a Nix derivation.

## Hello World
The template contains a `lab` repo with a single "hello" application and runscript from the [Genode Foundations](https://genode.org/documentation/genode-foundations/23.05/index.html) book. This demo provides a nice opportunity to demonstrate the various ways this flake can be used, as well as testing your setup.

### Building a System Image 
The simplest way to build a system image for the demo scenario is to build the Nix derivation.

```console
nix build
```

This will produce an ISO image located at `result/hello.iso`. You can run this image on Genode supported hardware, or in QEMU.

```console
qemu-system-x86_64 -cdrom result/hello.iso -m 64 -nographic
```

### Interactive Development Environment
It is often preferable to be able to tinker with source code in a more interactive environment. Nix provides a tool for creating reproducible shell environments. To prepare the Genode source tree, toolchain, and all other related dependencies, enter the Nix shell. 

```console 
nix-shell 
``` 

If you prefer to use nix flakes, `nix develop` may be used in place of the above command. This command will also set a few useful environment variables. 

| Variable | Default Value | Purpose |
|---|---|---|
| `SOURCE_DIR` | `"$(pwd)/./.build"` | The working directory for the build steps |
| `GENODE_DIR` | `"${SOURCE_DIR}/genode-src"` | The location of the root of the working copy of the Genode source tree |
| `BUILD_DIR` | `"${SOURCE_DIR}/build"` | The location of the Genode build directory |

These locations will not be created until you run the `unpackPhase` using the command below. 

```console 
runPhase unpackPhase 
``` 

Note that the `$SOURCE_DIR` directory created by the `unpackPhase` remains after you exit the Nix shell. Unless you need to "reset" the source tree, this command does not need to be executed again after returning to the Nix shell. 

You can interact directly with the build system by changing to the Genode build directory. 

```console 
cd ${BUILD_DIR} 
``` 

You can execute Genode tools/helper scripts located at `$GENODE_DIR/tool`. For example, additional ports can be prepared by running the following command. 

```console 
${GENODE_DIR}/tool/ports/prepare_port . . . 
``` 

The demo scenario can be built by running the `buildPhase`. 

```console 
runPhase buildPhase 
``` 

## Building Your Own Project
The Genode source tree is central to the build environment. Much of what this flake provides is convenience functions for aggregating sources and integrating them into the tree, making them accessible to the build system. The following sections will discuss components of the Genode build system, and how they are managed in Nix.

### Custom Repos
These refer to Genode repositories containing components, run scripts, etc. that are provided by your flake. During the `unpackPhase`, all repos stored in the [`repos`](templates/genode/repos) directory will be copied to `$GENODE_DIR/repos`.

To make these accessible to the build system, add a line similar to the following for each repository (i.e., subdirectory) to [`build.conf`](templates/genode/build.conf).

```makefile
REPOSITORIES += $(GENODE_DIR)/repos/REPO_NAME
```

### External Repos
These refer to Genode repositories that are not provided by your flake, but also not included in the base Genode source repository. The example used here is the [genode-world](https://github.com/genodelabs/genode-world) repository.

It is recommended that you allow these repositories to be managed as flake inputs. This allows easy updating of referenced commit hashes. To add a new external repo to the Genode source tree, add the following to your flake inputs

```nix
inputs = {
    . . .

    genode-world = {
        url = "github:genodelabs/genode-world";
        flake = false;
    };

    . . .
}

outputs = { ..., genode-world }:

. . .
```

and the following to the `repos` argument when calling `mkGenodeSrc`

```nix
genodeSrc = mkGenodeSrc {
    inherit genode;

    repos = {
        . . .

        # "world" is the name of the repo as it will appear in $GENODE_DIR/repos
        "world" = genode-world;

        . . .
    };

    ports = import ./.nix/ports.nix;
}
```

`genode-world` may be substituted for any valid Genode repository. Like with your custom repositories, don't forget to add the repo to the build system by adding the following line to `build.conf`

```makefile
REPOSITORIES += $(GENODE_DIR)/repos/world
```

### Ports
Due to restrictions imposed by Nix to protect reproducibility, all ports must be prepared when the Genode source tree is constructed. To prepare Genode ports in Nix derivation, a small amount of manual labor is required. Note that ports may be prepared as normal within the Nix shell environment using the `$GENODE_DIR/tool/ports/prepare_port` tool.

To prepare a port in a Nix derivation, all downloads must be prepared by Nix instead of Genode. The `ports` argument of the `mkGenodeSrc` function accepts a list of attribute sets containing required properties from Genode `*.port` files. Two types of ports are currently supported: git and archive. All required attributes can be obtained from the `*.port` and `*.hash` files. Examples are available [here](templates/genode/.nix/ports.nix).

The template manages ports in a separate [``.nix/ports.nix``](templates/genode/.nix/ports.nix) file, which is imported and passed to the `ports` argument in `mkGenodeSrc`. The `pkgs` argument passed to the function provides access to the entirety of Nixpkgs (useful when `extraInputs` is required).

The following attributes are required for all port types.

```nix
{
    # Example values from nova.port

    . . .

    # Name of the port obtained from the NAME.port file
    name = "nova";
    
    # Port type obtained from the postfix of the DOWNLOADS variable
    type = "git";
    
    # Value stored in NAME.hash
    hash = "33fbac63a46a1d91daa48833fb17e0ab4b0a04c7";

    # Value of the URL variable with all variables expanded
    url = "https://github.com/alex-ab/NOVA.git";

    . . .
}
```

In some cases, a port may check for additional dependencies required at build-time. Nix must be made aware of these to patch shell scripts. These dependencies may be provided using the optional `extraInputs` argument.

```nix
{
    # Example values from sel4.port

    . . .

    extraInputs = with pkgs; [
        # Additional packages here
        cmake

        . . .
    ];

    . . .
}
```

#### Git Ports
The following attributes are required to download a git port. 

```nix
{
    # Example values from nova.port

    . . .

    # Value of the REV variable with all variables expanded
    rev = "3e34fa6c35c55566ae57a1fd654262964ffcf544";
    
    # Value of the DIR variable with all variables expanded
    dir = "src/kernel/nova";

    . . .
}
```

#### Archive Ports
Similar to git ports, archive ports require additional attributes to properly fetch files.

```nix
{
    # Example values from vim.port

    . . .

    # Value of the SHA varible with all variables expanded
    sha256 = "56f330c33411d4fd3ae2017ea26b07b8bff9b3ac712d5a77f79ccd5374ee39f4";

    . . .
}
```

Note that the `sha256` attribute is distinct from the `hash` attribute.

## Updating Your Inputs
Nix flakes make updating the external dependencies of your project very simple. Each of the inputs to your flake is "locked" at a specific commit hash by `flake.lock`. To advance all inputs to the latest commit in the branch they are following, run the following command.

```console
nix flake update --commit-lock-file
```

Note that the `--commit-lock-file` is optional, but provides a nice commit message precisely describing the changes that were made. Keeping `flake.lock` updates in separate commits also makes it easy to revert if an update causes breakage.

To update a single input (e.g., `nixpkgs`), run the following command.

```console
nix flake lock --update-input nixpkgs --commit-lock-file
```

Again, the `--commit-lock-file` is optional.