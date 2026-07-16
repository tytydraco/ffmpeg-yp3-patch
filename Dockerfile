FROM debian:trixie-slim AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    gcc \
    git \
    libc6-dev \
    libdav1d-dev \
    libmp3lame-dev \
    libopus-dev \
    libvorbis-dev \
    libvpx-dev \
    make \
    pkg-config \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

# Add and use unprivileged user for more security during build
RUN useradd --create-home --shell /bin/bash user

USER user

WORKDIR /home/user

COPY . .

RUN ./build.sh


FROM debian:trixie-slim

# Only install runtime libraries
RUN apt-get update && apt-get install -y --no-install-recommends \
    libdav1d7 \
    libmp3lame0 \
    libopus0 \
    libvorbis0a \
    libvorbisenc2 \
    libvpx9 \
    && rm -rf /var/lib/apt/lists/*

# Copy binaries from build container
COPY --from=builder \
    /home/user/local/bin/* \
    /usr/local/bin/

WORKDIR /data

VOLUME /data
