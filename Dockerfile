FROM alpine:3 AS downloader
ARG BEPINEX_VERSION=5.4.23.4

WORKDIR /workspace
RUN wget https://github.com/BepInEx/BepInEx/releases/download/v${BEPINEX_VERSION}/BepInEx_linux_x64_${BEPINEX_VERSION}.zip &&\
    unzip BepInEx_linux_x64_${BEPINEX_VERSION}.zip -d /target &&\
    chmod a+x /target/run_bepinex.sh

FROM cm2network/steamcmd:steam

ARG DEBIAN_FRONTEND=noninteractive
USER root
# fix save and bepinex
RUN apt-get update && apt-get install libsqlite3-0 file -y && apt-get clean

USER steam
WORKDIR /opt/craftopia

# install game
RUN /home/steam/steamcmd/steamcmd.sh \
    +force_install_dir "/opt/craftopia" \
    +login anonymous \
    +app_update 1670340 validate \
    +quit

# install bepinex
COPY --from=downloader --chown=steam:steam /target /opt/craftopia/

# create config files
RUN timeout 10 ./Craftopia.x86_64 || exit 0

ENV WORLD_NAME=NoName
ENV WORLD_DIFFICULTY=1
ENV WORLD_GAME_MODE=1

ENV HOST_PORT=6587
ENV HOST_MAX_PLAYER_NUMBER=32
ENV HOST_USE_PASSWORD=0
ENV HOST_SERVER_PASSWORD=00000000

ENV SAVE_AUTO_SAVE_SEC=300
ENV SAVE_AUTO_SAVE_PER_HOUR=1

ENV FORCE_UPDATE=false
ENV ENABLE_MOD=false

COPY docker-entrypoint.sh /docker-entrypoint.sh

EXPOSE ${HOST_PORT}/udp

# fix permission
RUN mkdir -p /opt/craftopia/DedicatedServerSave /opt/craftopia/BepInEx/plugins /opt/craftopia/BepInEx/config
VOLUME [ "/opt/craftopia/DedicatedServerSave", "/opt/craftopia/BepInEx/plugins", "/opt/craftopia/BepInEx/config" ]

ENTRYPOINT [ "/docker-entrypoint.sh" ]
