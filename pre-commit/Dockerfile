# hadolint ignore=DL3006
FROM common_context AS common_context

# Set base_context in the downstream Bake file
# hadolint ignore=DL3006
FROM base_context
ARG USER=root
# Assume root role for installs
USER root
# Install git (if not already available) to spoof pre-commit environment
SHELL [ "/bin/bash", "-c" ]
RUN DEBIAN_FRONTEND=noninteractive \
  apt-get update \
  && if ! dpkg-query --status git ; then \
    apt-get install --allow-unauthenticated --no-install-recommends -y \
      git=1:2.39.5* ; \
  fi \
  && if ! dpkg-query --status locales ; then \
    apt-get install --allow-unauthenticated --no-install-recommends -y \
      locales=2.36* ; \
  fi \
  && rm -rf /var/lib/apt/lists/*

# Prep folder for pre-commit
ENV DEVCONTAINER_PRE_COMMIT=/opt/devcontainers/pre-commit
RUN \
  mkdir -p "$DEVCONTAINER_PRE_COMMIT" \
  && chmod a+rx "$DEVCONTAINER_PRE_COMMIT" \
  && chown -R $USER:$USER "$DEVCONTAINER_PRE_COMMIT"
# Apply spoof pre-commit executable
COPY pre-commit/pre-commit /usr/local/bin
USER ${USER}
# Create a temp repo and install the hooks from the config
# Load the config file from the downstream context
# hadolint ignore=DL3003,SC1091
RUN \
  --mount=type=bind,from=local_context,source=.pre-commit-config.yaml,target=/tmp/.pre-commit-config.yaml \
  python -m venv "$DEVCONTAINER_PRE_COMMIT/venv" \
  && source "$DEVCONTAINER_PRE_COMMIT/venv/bin/activate" \
  && mkdir "$DEVCONTAINER_PRE_COMMIT/tmp_repo" \
  && cd "$DEVCONTAINER_PRE_COMMIT/tmp_repo" \
  && cp /tmp/.pre-commit-config.yaml . \
  && git init . \
  && pip install --no-cache-dir pre-commit==4.0.1 \
  && pre-commit install-hooks \
  && cd "$DEVCONTAINER_PRE_COMMIT" \
  && rm -rf "$DEVCONTAINER_PRE_COMMIT/tmp_repo"

COPY --from=common_context on_create_command /opt/devcontainers/on_create_command
# Include pre-commit initialization in config for devcontainers onCreateCommand
COPY pre-commit/on_create_command /opt/devcontainers/on_create_command
