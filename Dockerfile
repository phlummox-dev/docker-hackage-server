FROM ubuntu:18.04@sha256:0fedbd5bd9fb72089c7bbca476949e10593cebed9b1fb9edf5b79dbbacddd7d6 \
   as build

ARG GHC_VERSION=8.2.2 \
    CABAL_VERSION=3.0

RUN  \
      apt-get update  \
  &&  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        ca-certificates             \
        git                         \
        libicu-dev                  \
        libssl-dev                  \
        netbase                     \
        openssl                     \
        software-properties-common  \
        unzip                       \
        zlib1g-dev                  \
  &&  apt-add-repository ppa:hvr/ghc \
  &&  apt-get update \
  &&  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
          cabal-install-${CABAL_VERSION} \
          ghc-${GHC_VERSION}  \
  # Remove  unnecessary stuff
  &&  apt-get autoclean \
  &&  apt-get clean -y  \
  &&  apt-get --purge -y autoremove \
  &&  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV PATH /opt/ghc/bin:$PATH

RUN mkdir /build
WORKDIR /build

ARG HACKAGE_VERSION=hackage-deployment-2020-05-03

RUN \
      cabal v2-update \
  &&  git clone https://github.com/haskell/hackage-server.git . \
  &&  git checkout ${HACKAGE_VERSION}

RUN \
      cabal v2-build --only-dependencies \
  &&  cabal v2-install --install-method=copy --constraint='text < 2.0'  hackage-repo-tool

ENV PATH /root/.cabal/bin:$PATH

RUN \
      hackage-repo-tool create-keys --keys keys \
  &&  cp keys/timestamp/*.private datafiles/TUF/timestamp.private \
  &&  cp keys/snapshot/*.private datafiles/TUF/snapshot.private \
  &&  hackage-repo-tool create-root --keys keys -o datafiles/TUF/root.json \
  &&  hackage-repo-tool create-mirrors --keys keys -o datafiles/TUF/mirrors.json \
  &&  cabal v2-build \
  &&  cabal v2-install --install-method=copy

###
# server

FROM ubuntu:18.04@sha256:0fedbd5bd9fb72089c7bbca476949e10593cebed9b1fb9edf5b79dbbacddd7d6

SHELL ["/bin/bash", "-c"]

ARG CABAL_DIR=/root/.cabal

ENV PATH ${CABAL_DIR}/bin:$PATH

COPY --from=build ${CABAL_DIR}/bin ${CABAL_DIR}/bin

RUN  \
      apt-get update  \
  &&  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        ca-certificates   \
        curl              \
        libicu60          \
        libssl1.1         \
        netbase           \
        zlib1g            \
  # Remove  unnecessary stuff
  &&  apt-get autoclean \
  &&  apt-get clean -y  \
  &&  apt-get --purge -y autoremove \
  &&  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*#

# setup server runtime environment

RUN mkdir /runtime
WORKDIR /runtime

COPY --from=build /build/datafiles /runtime/datafiles

RUN \
      hackage-server init --static-dir=datafiles \
  &&  rm -f state/db/*/*/*.lock \
  &&  rm -f state/db/*/*.lock

# This step might end up being somewhat flaky:
# in which case, the principled way of doing it would be
# to write custom Haskell code which exposes the
# "add-an-uploader" logic to the command-line.
RUN \
     set -vx; \
     hackage-server run  --static-dir=datafiles --base-uri=http://localhost:8080/ & \
     server_pid=$! \
  && sleep 4 \
  && curl -X POST -u 'admin:admin' -F 'user=admin' -F 'reason=justbecause' \
          http://localhost:8080/packages/uploaders/ \
  && sleep 2 \
  && kill $server_pid

CMD ["bash", "-c", "rm -f state/db/*/*/*.lock && rm -f state/db/*/*.lock && hackage-server run --static-dir=datafiles"]

EXPOSE 8080

