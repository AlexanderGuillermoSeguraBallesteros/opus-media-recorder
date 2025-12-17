FROM trzeci/emscripten:1.39.10-upstream AS emscripten_base
FROM node:12.16.2-buster

# Copy pre-compiled content of Emscripten SDK to target iamge
COPY --from=emscripten_base /emsdk_portable /emsdk_portable

# Fix Debian Buster repositories (moved to archive)
RUN echo "deb http://archive.debian.org/debian buster main" > /etc/apt/sources.list && \
    echo "deb http://archive.debian.org/debian-security buster/updates main" >> /etc/apt/sources.list && \
    echo "deb http://archive.debian.org/debian buster-updates main" >> /etc/apt/sources.list

# install required tools to run Emscripten SDK
RUN apt-get update && apt-get install -y \
      build-essential cmake python python-pip ca-certificates wget \
 && rm -rf /var/lib/apt/lists/*


# install other tools
RUN apt-get update && apt-get install -y \
      gconf-service \
 && rm -rf /var/lib/apt/lists/*

# install X to run a browser in headless mode (for testing)
RUN apt-get update && apt install -y \
      libasound2 libatk1.0-0 libc6 libcairo2 libcups2 \
      libdbus-1-3 libexpat1 libfontconfig1 libgcc1 libgconf-2-4 libgdk-pixbuf2.0-0 \
      libglib2.0-0 libgtk-3-0 libnspr4 libpango-1.0-0 libpangocairo-1.0-0 libstdc++6 \
      libx11-6 libx11-xcb1 libxcb1 libxcomposite1 libxcursor1 libxdamage1 libxext6 \
      libxfixes3 libxi6 libxrandr2 libxrender1 libxss1 libxtst6 \
      fonts-liberation libappindicator1 libnss3 xdg-utils \
 && rm -rf /var/lib/apt/lists/*

# build directory
RUN mkdir /build \
 && chmod 777 /build
WORKDIR /build

# Fix git submodule URLs if they exist (for when repo is copied into container)
# This ensures submodules use GitHub mirrors instead of git.xiph.org
# Note: This runs at build time, but the actual fix should be in the source code
# This is a safety net in case old URLs are present
RUN if [ -f .gitmodules ]; then \
      sed -i 's|https://git.xiph.org/opus.git|https://github.com/xiph/opus.git|g' .gitmodules && \
      sed -i 's|https://git.xiph.org/ogg.git|https://github.com/xiph/ogg.git|g' .gitmodules && \
      sed -i 's|https://git.xiph.org/speexdsp.git|https://github.com/xiph/speexdsp.git|g' .gitmodules; \
    fi && \
    if [ -f .git/config ]; then \
      sed -i 's|https://git.xiph.org/opus.git|https://github.com/xiph/opus.git|g' .git/config && \
      sed -i 's|https://git.xiph.org/ogg.git|https://github.com/xiph/ogg.git|g' .git/config && \
      sed -i 's|https://git.xiph.org/speexdsp.git|https://github.com/xiph/speexdsp.git|g' .git/config && \
      git submodule sync 2>/dev/null || true; \
    fi

# Use entrypoint that comes with Emscripten. This is a way to to activate Emscripten Tools.
ENTRYPOINT ["/emsdk_portable/entrypoint"]
