# Set base_context in the downstream Bake file
FROM base_context

USER root
COPY --from=docker_image /usr/local/bin/docker /usr/local/bin/docker
ARG DOCKER_GID=800
RUN groupadd --gid $DOCKER_GID docker
