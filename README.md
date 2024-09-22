# dockerfile-partials

Dockerfile partials and devcontainer [bake](https://docs.docker.com/build/bake/introduction/) files for re-use across multiple applications.

## Devcontainer bake files

Each Dockerfile partial is accompanied by a `devcontainer-bake.hcl` [bake](https://docs.docker.com/build/bake/introduction/) config file, and a common bake file is defined at the repository root. These are intended to make composition of devcontainer image contents trivial. They are designed to work with the [devcontainer-cache-build initialize script](https://github.com/rcwbr/devcontainer-cache-build/tree/main?tab=readme-ov-file#initialize-script).

Using these bake files remotely requires setting the primary build context to this repo by [remote definition](https://docs.docker.com/build/bake/remote-definition/). Because of [this limitation of remote bake build contexts](https://github.com/docker/buildx/blob/056cf8a7ca083d91eccf9200e7e2c99ff170bbaf/bake/bake.go#L1213C6-L1213C73)

> ```We don't currently support reading a remote Dockerfile with a local context when doing a remote invocation because we automatically derive the dockerfile from the context atm```

this means that any build contexts required by the Dockerfile partial must be provided via a [local directory `contexts` context](https://docs.docker.com/build/bake/reference/#targetcontexts) rather than the primary build context. For example, the `pre-commit` Dockerfile [reads from the `local_context` context](https://github.com/rcwbr/dockerfile-partials/blob/086902fb92beb8ab2bf887ff6a6a141804762eb9/pre-commit/Dockerfile#L10C26-L10C39) [set to `BAKE_CMD_CONTEXT`](https://github.com/rcwbr/dockerfile-partials/blob/086902fb92beb8ab2bf887ff6a6a141804762eb9/pre-commit/devcontainer-bake.hcl#L11). This allows it to consume contents of the downstream build context.

### Devcontainer bake files devcontainer-cache-build usage

In a `devcontainer.json` leveraging the [devcontainer-cache-build initialize script](https://github.com/rcwbr/devcontainer-cache-build/tree/main?tab=readme-ov-file#initialize-script), add the following configuration to the `initializeCommand` before the `curl` to the initialize script:

#### Devcontainer bake files devcontainer-cache-build initializeCommand config

```json5
...
  "initializeCommand": [
    ...
    "export DEVCONTAINER_DEFINITION_TYPE=bake",
    "&& export DEVCONTAINER_DEFINITION_FILES=\"devcontainer-bake.hcl [path to each desired partial bake file] cwd://.devcontainer/devcontainer-bake.hcl\"", 
    "&& export DEVCONTAINER_BUILD_ADDITIONAL_ARGS=https://github.com/rcwbr/dockerfile-partials.git#0.1.0",
    ...
  ]
...
```

`DEVCONTAINER_DEFINITION_FILES` must begin with `devcontainer-bake.hcl` and end with `cwd://.devcontainer/devcontainer-bake.hcl` (see [Devcontainer bake files devcontainer-cache-build .devcontainer/devcontainer-bake.hcl config](#devcontainer-bake-files-devcontainer-cache-build-devcontainerdevcontainer-bakehcl-config), and with each desired partial bake file in between (ordering is important for override priority). For example:

```bash
export DEVCONTAINER_DEFINITION_FILES=\"devcontainer-bake.hcl useradd/devcontainer-bake.hcl pre-commit/devcontainer-bake.hcl cwd://.devcontainer/devcontainer-bake.hcl\""
```

#### Devcontainer bake files devcontainer-cache-build .devcontainer/devcontainer-bake.hcl config

To join the devcontainer partial bake files, you must define a bake file local to your project that configures targets from each partial you select. It must define at least the `devcontainer_layers` variable as a list with the names of each selected partial, and override the `base_context` for at least the first partial target. For example:

```hcl
variable "devcontainer_layers" {
  default = [
    "useradd",
    "pre-commit"
  ]
}

target "useradd" {
  contexts = {
    base_context = "docker-image://python:3.12.4"
  }
}
```

Optionally, `target`s may be configured for each layer. Values provided to these will override those defined in the partials `devcontainer-bake.hcl`.

### Devcontainer bake files direct usage

The partial bake files may be used manually through a command like this:

```bash
docker buildx bake --file devcontainer-bake.hcl [--file arg for each desired partial bake file] --file cwd://.devcontainer/devcontainer-bake.hcl https://github.com/rcwbr/dockerfile-partials.git#0.1.0
```

## Dockerfile partials

### docker-client

The docker-client Dockerfile defines steps to install the [Docker CLI client](https://docs.docker.com/reference/cli/docker/) in a Docker image. It copies the CLI executable from the [Docker docker image](https://hub.docker.com/_/docker).

#### docker-client Dockerfile usage

The recommended usage is via the [Devcontainer bake files](#devcontainer-bake-files). It is also possible to use the Dockerfile partial directly.

Use a [Bake](https://docs.docker.com/reference/cli/docker/buildx/bake/) config file, and set the `base_context` context as the image to which to apply the docker-client installation. For example:

```hcl
target "base" {
  dockerfile = "Dockerfile"
}

target "default" {
  context = "https://github.com/rcwbr/dockerfile_partials.git#0.1.0"
  dockerfile = "docker-client/Dockerfile"
  contexts = {
    base_context = "target:base"
  }
}
```

The args accepted by the Dockerfile include:

| Variable | Required | Default | Effect |
| --- | --- | --- | --- |
| `DOCKER_GID` | &cross | `800` | Group ID of the docker user group |
| `USER` | &cross; | `"root"` | Username to grant access to the Docker daemon |


#### docker-client bake file usage

The docker-client partial contains a devcontainer bake config file. See [Devcontainer bake files](#devcontainer-bake-files) for general usage. The docker-client bake config file accepts the following inputs:

| Variable | Required | Default | Effect |
| --- | --- | --- | --- |
| `DOCKER_GID` | &cross | `800` | See [docker-client Dockerfile](#docker-client-dockerfile-usage) |
| `USER` | &cross; | `"root"` | See [docker-client Dockerfile](#docker-client-dockerfile-usage) |

#### docker-client devcontainer usage

The docker-client partial installs only the client CLI by default. To leverage the container host's Docker daemon, the relevant socket must be mounted at runtime. In a [`devcontainer.json`](https://containers.dev/implementors/json_reference/), the following content must be included:

```jsonc
{
  "image": "[image including docker-client layers]",
  "mounts": [
    { "source": "/var/run/docker.sock", "target": "/var/run/docker.sock", "type": "bind" }
  ]
}
```

### pre-commit

The pre-commit Dockerfile defines steps to install [pre-commit](https://pre-commit.com/) and install the hooks required by a repo configuration.

#### pre-commit Dockerfile usage

The recommended usage is via the [Devcontainer bake files](#devcontainer-bake-files). It is also possible to use the Dockerfile partial directly.

Use a [Bake](https://docs.docker.com/reference/cli/docker/buildx/bake/) config file, and set the `base_context` context as the image to which to apply the pre-commit installation, and the `local_context` to the directory from which the `.pre-commit-config.yaml` can be loaded (generally [`BAKE_CMD_CONTEXT`](https://docs.docker.com/build/bake/reference/#built-in-variables)). Additionally, provide appropriate values for the `USER` build arg. For example:

```hcl
target "base" {
  dockerfile = "Dockerfile"
}

target "default" {
  context = "https://github.com/rcwbr/dockerfile_partials.git#0.1.0"
  dockerfile = "pre-commit/Dockerfile"
  contexts = {
    base_context = "target:base"
    local_context = BAKE_CMD_CONTEXT
  }
  args = {
    USER = "myuser"
  }
}
```

The args accepted by the Dockerfile include:

| Variable | Required | Default | Effect |
| --- | --- | --- | --- |
| `USER` | &cross; | `"root"` | Username to assume for hook pre-loading |

#### pre-commit bake file usage

The pre-commit partial contains a devcontainer bake config file. See [Devcontainer bake files](#devcontainer-bake-files) for general usage. The pre-commit bake config file accepts the following inputs:

| Variable | Required | Default | Effect |
| --- | --- | --- | --- |
| `USER` | &cross; | `"root"` | See [pre-commit Dockerfile](#pre-commit-dockerfile-usage) |

#### pre-commit Codespaces usage

For use in [Codespaces](https://github.com/features/codespaces) devcontainers, the build args must be set to the following values:

- `USER`: `codespace`

These values may be hard-coded in the Bake config file, or may be exposed as variables for compatibility with local environments.

```hcl
variable "USER" {
  default = "root"
}
...
  args = {
    USER = "${USER}"
  }
...
```

If exposed as variables, the appropriate values for Codespaces use must be [set as secrets](https://docs.github.com/en/codespaces/managing-your-codespaces/managing-your-account-specific-secrets-for-github-codespaces#adding-a-secret) so as to be available during Codespace provisioning.

### useradd

The useradd Dockerfile defines steps to add a user to the image, with configurable user name, id, and group id.

#### useradd Dockerfile usage

The recommended usage is via the [Devcontainer bake files](#devcontainer-bake-files). It is also possible to use the Dockerfile partial directly.

Use a [Bake](https://docs.docker.com/reference/cli/docker/buildx/bake/) config file, and set the `base_context` context as the image to which to apply the user addition. Additionally, provide appropriate values for the `USER`, `USER_UID`, and `USER_GID` build args. For example:

```hcl
target "base" {
  dockerfile = "Dockerfile"
}

target "default" {
  context = "https://github.com/rcwbr/dockerfile_partials.git#0.1.0"
  dockerfile = "useradd/Dockerfile"
  contexts = {
    base_context = "target:base"
  }
  args = {
    USER = "myuser"
    USER_UID = 1000
    USER_GID = 1000
  }
}
```

The args accepted by the Dockerfile include:

| Variable | Required | Default | Effect |
| --- | --- | --- | --- |
| `USER` | &check; | N/A | Username of the user to create |
| `EXTRA_GID_ARGS` | &cross; | `""` | Extra `--gid [id]` args to apply to the useradd command |
| `USER_UID` | &cross; | `1000` | User UID for the user to create |
| `USER_GID` | &cross; | `$USER_UID` | User GID for the user to create |

#### useradd bake file usage

The useradd partial contains a devcontainer bake config file. See [Devcontainer bake files](#devcontainer-bake-files) for general usage. The useradd bake config file accepts the following inputs:

| Variable | Required | Default | Effect |
| --- | --- | --- | --- |
| `USER` | &cross; | `"root"` | See [useradd Dockerfile](#useradd-dockerfile-usage) |
| `EXTRA_GID_ARGS` | &cross; | `""` | See [useradd Dockerfile](#useradd-dockerfile-usage) |
| `UID` | &cross; | `0` | Maps to `USER_UID`. See [useradd Dockerfile](#useradd-dockerfile-usage) |
| `GID` | &cross; | `${UID}` | Maps to `USER_GID`.See [useradd Dockerfile](#useradd-dockerfile-usage) |

#### useradd Codespaces usage

For use in [Codespaces](https://github.com/features/codespaces) devcontainers, the build args must be set to the following values:

- `USER`: `codespace`
- `UID`: `1000`

These values may be hard-coded in the Bake config file, or may be exposed as variables for compatibility with local environments.

```hcl
variable "USER" {
  default = "root"
}
variable "UID" {
  default = 0
}
variable "GID" {
  // Use the user id as group id unless set
  default = "${UID}"
}

...
  args = {
    USER = "${USER}"
    USER_UID = "${UID}"
    USER_GID = "${GID}"
  }
...
```

If exposed as variables, the appropriate values for Codespaces use must be [set as secrets](https://docs.github.com/en/codespaces/managing-your-codespaces/managing-your-account-specific-secrets-for-github-codespaces#adding-a-secret) so as to be available during Codespace provisioning.
