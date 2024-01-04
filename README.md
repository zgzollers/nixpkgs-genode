# Genode Nixpkgs
This repository provides useful Nix flakes/packages for developing and building systems based on the [Genode](https://genode.org). Some familiarity with Nix (flakes) is reccommended.

# Usage
## Flake Template
To clone the provided flake template and create a new genode project, run the following command.

```
nix flake new -t github:zgzollers/nixpkgs-genode#genode ./genode-project
```

Nix flakes can only access files that are added to a git repository. To initilize a new repository in the flake directory, run

```console
$ git init && git add .
```

Make any desired changes to the initial template, then create the initial flake lock file by running

```console
$ nix flake update && git add flake.lock
```

Finally, commit the changes. For some yet-unclear reason, the genode build system will fail to build/run system scenarios and components if the initial flake template (in particular the `.gitignore`) is not committed to the repository.

```console
$ git commit -m "Initial commit"
```

## Hello World
The template contains a `lab` repo with a single "hello" application and runscript from the [Genode Foundations](https://genode.org/documentation/genode-foundations/23.05/index.html) book. To build and run this scenario, run the following commands from inside the cloned template.

```console
$ nix develop # You can also use nix-shell here to avoid using flakes
```

``` console
$ runPhase unpackPhase
```

```console
$ runPhase buildPhase
```

This sequence of commands should build a genode system image and run it using QEMU.

## Building Your Own Project
At this point, the entire world of Genode is at your disposal. Below are a few recommendations for managing the Nix portion of the project.

* Genode ports should be prepared using the Nix derivation. The template prepares these in the `postUnpack` hook.

* The `default.nix` file can be removed if compatability with `nix-shell` is not needed.

* The `build.conf` file is copied to `$BUILD_DIR/etc/build.conf` during the `postUnpack` hook. In general, `runPhase unpackPhase` should be run after every change to source files.

# Known Issues
## Genode Ports
The genode build system implements its own nix-style checks on downloaded port archives. Work is being done to translate these to nix derivations. Unfortunately, ports currently cannot be prepared in a nix derivation (since no network access is provided). Until this feature is completed, runscripts and components requiring ports can only be prepared in a Nix shell.