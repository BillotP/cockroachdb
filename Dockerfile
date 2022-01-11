##
#
#   1. BUILD
#
##
FROM golang:1.15 as build
ARG version=v21.2.4
ENV version=$version
ENV DEBIAN_FRONTEND=noninteractive
# Install build dependency
RUN apt-get update && apt-get -y upgrade && apt-get -y install \
    gcc \
    cmake \
    ccache \
    autoconf \
    wget \
    bison \
    libncurses-dev
# Download $version release tarball  
RUN wget -q --show-progress https://binaries.cockroachdb.com/cockroach-${version}.src.tgz
# Extract it
RUN tar xvf cockroach-${version}.src.tgz
RUN pwd && ls
# Set extracted folder as working directory
WORKDIR /go/cockroach-${version}
RUN mkdir -p /usr/local/lib/cockroach
# Install binary locally
RUN make build 
RUN make install
# Copy libs too
RUN cp /go/cockroach-${version}/src/github.com/cockroachdb/cockroach/lib/* /usr/local/lib/cockroach/
# Have some debug infos
RUN whereis cockroach && whereis bash
##
#
#   2. RUN
#
##
FROM busybox:glibc
WORKDIR /cockroach/
ENV PATH=/cockroach:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV COCKROACH_CHANNEL=kubernetes-secure
RUN mkdir -p /cockroach/
RUN mkdir /cockroach/cockroach-certs
# Copy timezone info
COPY --from=build /usr/share/zoneinfo /usr/share/zoneinfo
# Copy dynamic lib
COPY --from=build /lib/ /lib/
COPY --from=build /bin/bash /bin/bash
COPY --from=build /usr/local/lib/cockroach /usr/local/lib/
COPY --from=build /usr/lib/*-linux-gnu/libstdc++.so.6 /lib/
COPY --from=build /usr/local/bin/cockroach /cockroach/cockroach
ENV LD_LIBRARY_PATH=/lib/
# Ports : PSQL  Admin GUI
EXPOSE 26257 8080
ENTRYPOINT ["/cockroach/cockroach"]
