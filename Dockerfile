FROM archlinux/base:latest as builder
MAINTAINER François LAROCHE "fl@make.org"

# Let's run stuff
RUN \
  # First, update everything (start by keyring and pacman)
  pacman -Sy && \
  # Install what is needed to build xmr-stak
  pacman -S gcc fakeroot git sudo vim tree iproute2 inetutils --noconfirm --needed && \
  # Generate and set locale en_US.UTF-8
  echo 'en_US.UTF-8 UTF-8' > /etc/locale.gen && locale-gen
ENV LANG en_US.UTF-8

RUN \
  # Create an user
  useradd -m -G wheel -s /bin/bash user && \
  # Install sudo and configure it
  pacman -S sudo --noconfirm && \
  echo '%wheel ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

USER user
WORKDIR /home/user
RUN \
  # Get xmr-stak from AUR
  git clone https://aur.archlinux.org/bloop.git && \
  cd bloop  && makepkg -s --noconfirm && ls -l


FROM archlinux/base

MAINTAINER technical@make.org

COPY --from=builder \
  /home/user/bloop/bloop-*.pkg.tar.xz /tmp/.

RUN pacman -Sy && \
  pacman -S archlinux-keyring --noconfirm && \
  pacman -S pacman --noconfirm && \
  pacman-db-upgrade && \
  pacman -Su --noconfirm && \
  pacman -U /tmp/bloop-*.pkg.tar.xz --noconfirm && \
  pacman -S git openssh docker gcc make sed awk gzip grep curl vim tree iproute2 inetutils jdk13-openjdk sbt jq --noconfirm --needed && \
  /bin/sh -c "bloop server &" && echo "Downloading bloop" && \
  curl https://cdn.azul.com/zulu/bin/zulu13.29.9-ca-jdk13.0.2-linux_x64.tar.gz --output - |tar -xzC /usr/lib/jvm && \
  unlink /usr/lib/jvm/default && unlink /usr/lib/jvm/default-runtime && \
  ln -sf /usr/lib/jvm/zulu13.29.9-ca-jdk13.0.2-linux_x64 /usr/lib/jvm/default && \
  ln -sf /usr/lib/jvm/zulu13.29.9-ca-jdk13.0.2-linux_x64 /usr/lib/jvm/default-runtime && \
  locale-gen en_US.UTF-8 && \
  pacman -Scc --noconfirm

ENV LANG=en_US.UTF-8
CMD ["/usr/bin/bash"]
