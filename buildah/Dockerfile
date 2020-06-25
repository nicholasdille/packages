FROM registry.fedoraproject.org/fedora:latest
ENV GOPATH=/root/buildah

RUN useradd build \
 && yum -y update \
 && yum -y reinstall shadow-utils \
 && yum -y install --enablerepo=updates-testing \
     make \
     golang \
     bats \
     btrfs-progs-devel \
     device-mapper-devel \
     glib2-devel \
     gpgme-devel \
     libassuan-devel \
     libseccomp-devel \
     git \
     bzip2 \
     go-md2man \
     runc \
     fuse-overlayfs \
     fuse3 \
     containers-common
     
RUN mkdir /root/buildah \
 && git clone https://github.com/containers/buildah /root/buildah/src/github.com/containers/buildah \
 && cd /root/buildah/src/github.com/containers/buildah \
 && export DISABLE_CGO=1 \
 && make EXTRA_LDFLAGS='-w -extldflags "-static"' \
 && make install

ADD https://raw.githubusercontent.com/containers/buildah/master/contrib/buildahimage/stable/containers.conf /etc/containers/

# Adjust storage.conf to enable Fuse storage.
RUN chmod 644 /etc/containers/containers.conf; sed -i -e 's|^#mount_program|mount_program|g' -e '/additionalimage.*/a "/var/lib/shared",' -e 's|^mountopt[[:space:]]*=.*$|mountopt = "nodev,fsync=0"|g' /etc/containers/storage.conf
RUN mkdir -p /var/lib/shared/overlay-images /var/lib/shared/overlay-layers; touch /var/lib/shared/overlay-images/images.lock; touch /var/lib/shared/overlay-layers/layers.lock

# Set an environment variable to default to chroot isolation for RUN
# instructions and "buildah run".
ENV BUILDAH_ISOLATION=chroot
