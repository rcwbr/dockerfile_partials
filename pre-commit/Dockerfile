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
  && if [[ ! dpkg-query --status git ]] ; then \
    apt-get install --allow-unauthenticated --no-install-recommends -y \
      git=1:2.39.5* ; \
  fi \
  && rm -rf /var/lib/apt/lists/*
COPY pre-commit /usr/local/bin
USER ${USER}
# Create a temp repo and install the hooks from the config
# Load the config file from the downstream context
# hadolint ignore=DL3003,SC1091
RUN \
  --mount=type=bind,from=local_context,source=.pre-commit-config.yaml,target=/tmp/.pre-commit-config.yaml \
  python -m venv "$HOME/pre-commit-venv" \
  && source "$HOME/pre-commit-venv/bin/activate" \
  && mkdir "$HOME/tmp_repo" \
  && cd "$HOME/tmp_repo" \
  && cp /tmp/.pre-commit-config.yaml . \
  && git init . \
  && pip install --no-cache-dir pre-commit==4.0.1 \
  && pre-commit install-hooks \
  && cd \
  && rm -rf "$HOME/tmp_repo"
