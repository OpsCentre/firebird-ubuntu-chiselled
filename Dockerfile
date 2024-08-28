# Build the chiselled filesystem based on the desired slices.
FROM ubuntu:24.04 AS base

# Install Firebird v5
FROM base AS firebird

ADD https://raw.githubusercontent.com/IBSurgeon/firebirdlinuxinstall/main/ubuntu24/fb_vanilla_ub24-50.sh ./fb_vanilla_ub24-50.sh

RUN chmod +x ./fb_vanilla_ub24-50.sh && \
    ./fb_vanilla_ub24-50.sh && \
    rm -f ./fb_vanilla_ub24-50.sh

FROM base AS chisel

# Get chisel binary
ADD https://github.com/canonical/chisel/releases/download/v0.10.0/chisel_v0.10.0_linux_amd64.tar.gz chisel.tar.gz

RUN tar -xvf chisel.tar.gz -C /usr/bin/

RUN apt-get update \
   && DEBIAN_FRONTEND=noninteractive apt-get install -y ca-certificates
   
WORKDIR /rootfs

RUN chisel cut --release ubuntu-24.04 --root /rootfs \
   base-files_base \
   base-files_release-info \
   ca-certificates_data \
   libgcc-s1_libs \
   libc6_libs \
   libicu74_libs \
   tzdata_zoneinfo

# Make the chiselled filesystem the only thing present in the final image.
FROM scratch

COPY --from=chisel /rootfs /

COPY --from=firebird /opt/firebird /opt/firebird
COPY --from=firebird /usr/lib/x86_64-linux-gnu/libtommath.so.1 /usr/lib/x86_64-linux-gnu/libtommath.so.1

VOLUME ["/databases"]

EXPOSE 3050/tcp

ENTRYPOINT ["/opt/firebird/bin/fbguard"]