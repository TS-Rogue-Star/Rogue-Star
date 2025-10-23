#RS Edit Start: Ubuntu Xenial has been out of support for ages, and has a lot of vulnerabilities
#Ubuntu is based on Debian, which still has support for i386. It should just work.
FROM --platform=linux/386 debian:trixie AS base
#RS Edit End

#RS EDIT START
ARG BYOND_MAJOR=516
ARG BYOND_MINOR=1666
#RS EDIT END

RUN apt-get update \
    && apt-get install -y \
    curl \
    unzip \
    make \
    libstdc++6 \
    #RS Edit Start: Need new package (DameonOwen, October 2025)
    libcurl4-openssl-dev \
    #RS Edit End
    #RS Edit Start: Add user agent per https://github.com/tgstation/tgstation/pull/91101 (Lira, May 2025)
    && curl -H "User-Agent: RogueStar/1.0 CI Script" "https://www.byond.com/download/build/${BYOND_MAJOR}/${BYOND_MAJOR}.${BYOND_MINOR}_byond_linux.zip" -o byond.zip \
    #RS Edit End
    && unzip byond.zip \
    && cd byond \
    && sed -i 's|install:|&\n\tmkdir -p $(MAN_DIR)/man6|' Makefile \
    && make install \
    && chmod 644 /usr/local/byond/man/man6/* \
    && apt-get purge -y --auto-remove curl unzip make \
    && cd .. \
    && rm -rf byond byond.zip /var/lib/apt/lists/*

FROM base AS rust_g

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    git \
    ca-certificates

WORKDIR /rust_g

RUN apt-get install -y --no-install-recommends \
    libssl-dev \
    pkg-config \
    curl \
    gcc-multilib \
    && curl https://sh.rustup.rs -sSf | sh -s -- -y --default-host i686-unknown-linux-gnu \
    && git init \
    # RS Edit Start - Use TGStation (DameonOwen, October 2025)
    && git remote add origin https://github.com/tgstation/rust-g
    # RS Edit End

COPY _build_dependencies.sh .

RUN /bin/bash -c "source _build_dependencies.sh \
    && git fetch --depth 1 origin \$RUST_G_VERSION" \
    && git checkout FETCH_HEAD \
    && ~/.cargo/bin/cargo build --release

FROM base AS dm_base

WORKDIR /vorestation

FROM dm_base AS build

COPY . .

RUN DreamMaker -max_errors 0 vorestation.dme

FROM dm_base

EXPOSE 2303

RUN apt-get update \
    && apt-get update \
    && apt-get upgrade -y \
    && apt-get dist-upgrade -y \
    && apt-get install -y --no-install-recommends \
    libmariadb-dev \
    mariadb-client \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /root/.byond/bin

COPY --from=build /vorestation/ ./
COPY --from=rust_g /rust_g/target/release/librust_g.so ./librust_g.so

#VOLUME [ "/vorestation/config", "/vorestation/data" ]

ENTRYPOINT [ "DreamDaemon", "vorestation.dmb", "-port", "2303", "-trusted", "-close", "-verbose" ]
