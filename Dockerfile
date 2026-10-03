# Plumbline in a container: the plumbline executable and the GnuCOBOL
# run-time library it needs, without a COBOL compiler.
#
#   docker build -t plumbline .
#   docker run --rm -v "$PWD:/work" plumbline check -I copybooks src/*.cbl
#
# The first stage builds GnuCOBOL from its release tarball, pinned by
# checksum as in CI, and then Plumbline; the second keeps only what
# runs.

FROM debian:bookworm-slim AS build

ARG GNUCOBOL_VERSION=3.2
ARG GNUCOBOL_SHA256=3bb48af46ced4779facf41fdc2ee60e4ccb86eaa99d010b36685315df39c2ee2

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential ca-certificates curl xz-utils \
        libgmp-dev libdb-dev libncurses-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp/gnucobol
RUN curl -sSfLO "https://ftp.gnu.org/gnu/gnucobol/gnucobol-${GNUCOBOL_VERSION}.tar.xz" \
    && echo "${GNUCOBOL_SHA256}  gnucobol-${GNUCOBOL_VERSION}.tar.xz" | sha256sum -c - \
    && tar xf "gnucobol-${GNUCOBOL_VERSION}.tar.xz" \
    && cd "gnucobol-${GNUCOBOL_VERSION}" \
    && ./configure --prefix=/opt/gnucobol \
    && make -j"$(nproc)" \
    && make install

ENV PATH=/opt/gnucobol/bin:$PATH \
    LD_LIBRARY_PATH=/opt/gnucobol/lib

WORKDIR /src
COPY Makefile ./
COPY copy copy
COPY src src
RUN make

FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libgmp10 libdb5.3 libncursesw6 \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --create-home --uid 1000 plumbline

COPY --from=build /opt/gnucobol/lib /opt/gnucobol/lib
# The run-time configuration libcob reads at start-up.
COPY --from=build /opt/gnucobol/share/gnucobol/config /opt/gnucobol/share/gnucobol/config
COPY --from=build /src/build/bin/plumbline /usr/local/bin/plumbline

ENV LD_LIBRARY_PATH=/opt/gnucobol/lib

USER plumbline
WORKDIR /work
ENTRYPOINT ["plumbline"]
CMD ["--help"]
