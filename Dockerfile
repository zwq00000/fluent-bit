# syntax=docker/dockerfile:1

# ---- build stage: compile patched fluent-bit from source ----
FROM ubuntu:22.04 AS build
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential cmake git flex bison \
      libssl-dev libsystemd-dev ca-certificates && \
      rm -rf /var/lib/apt/lists/*
WORKDIR /src
COPY . /src
RUN cmake -B build -S . \
      -DCMAKE_BUILD_TYPE=Release \
      -DFLB_RELEASE=On \
      -DFLB_TESTING=Off \
      -DFLB_BINARY=On \
      -DFLB_JEMALLOC=On \
      -DFLB_SQLDB=On \
      -DFLB_HTTP_SERVER=On \
      -DFLB_BACKTRACE=Off \
      -DFLB_SYSTEMD=Off && \
    cmake --build build --parallel "$(nproc)" && \
    strip build/fluent-bit

# ---- runtime stage ----
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
      libssl3 libstdc++6 zlib1g ca-certificates && \
      rm -rf /var/lib/apt/lists/* && \
      mkdir -p /etc/fluent-bit
COPY --from=build /src/build/fluent-bit /usr/local/bin/fluent-bit
COPY conf/fluent-bit.conf /etc/fluent-bit/fluent-bit.conf
ENTRYPOINT ["/usr/local/bin/fluent-bit"]
CMD ["-c", "/etc/fluent-bit/fluent-bit.conf"]
