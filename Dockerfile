FROM archlinux:base as builder
MAINTAINER François LAROCHE "fl@make.org"

# Let's run stuff
RUN \
  # First, update everything (start by keyring and pacman)
  pacman -Sy && \
  # Install what is needed to build dependencies
  pacman -S gcc fakeroot git sudo vim tree iproute2 inetutils --noconfirm --needed && \
  # Generate and set locale en_US.UTF-8
  echo 'en_US.UTF-8 UTF-8' > /etc/locale.gen && locale-gen
ENV LANG en_US.UTF-8

RUN \
  # Create an user
  useradd -m -G wheel -s /bin/bash user && \
  # Install sudo and configure it
  pacman -S sudo awk --noconfirm && \
  echo '%wheel ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

USER user
WORKDIR /home/user
RUN \
  # Get jdk, coursier and bloop from AUR
  git clone https://aur.archlinux.org/zulu-14-bin.git && \
  cd zulu-14-bin && makepkg -s --noconfirm && \
  sudo pacman -U zulu-14-bin*.pkg.tar.zst --noconfirm && \
  cd .. && git clone https://aur.archlinux.org/coursier.git && \
  cd coursier && makepkg -s --noconfirm && ls -l && \
  sudo pacman -U coursier-*.zst --noconfirm && \
  cd .. && git clone https://aur.archlinux.org/bloop.git && \
  cd bloop && makepkg -s --noconfirm


FROM archlinux:base

MAINTAINER technical@make.org

COPY --from=builder \
  /home/user/zulu-14-bin/zulu-14-bin-*.pkg.tar.zst /tmp/
COPY --from=builder \
  /home/user/coursier/coursier-*.zst /tmp/
COPY --from=builder \
  /home/user/bloop/bloop*.zst /tmp/

RUN pacman -Sy && \
  pacman -S archlinux-keyring --needed --noconfirm && \
  pacman -S pacman --needed --noconfirm && \
  pacman-db-upgrade && \
  pacman -Su --noconfirm && \
  pacman -U /tmp/zulu-14-bin*.pkg.tar.zst --noconfirm --needed && \
  ls -l /usr/lib/jvm && \
  archlinux-java set zulu-14 && \
  pacman -U /tmp/coursier-*.zst --noconfirm && pacman -U /tmp/bloop-*zst --noconfirm && \
  pacman -S git openssh docker gcc make sed awk gzip grep curl vim tree iproute2 inetutils sbt jq git-lfs --noconfirm --needed && \
  git lfs install &&\
  locale-gen en_US.UTF-8 && \
  pacman -Scc --noconfirm

ENV LANG=en_US.UTF-8
CMD ["/usr/bin/bash"]
