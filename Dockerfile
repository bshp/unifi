# Ocie Version, e.g 22.04 unquoted
ARG OCIE_VERSION
    
ARG UNIFI_VERSION=""
    
FROM bshp/ocie:${OCIE_VERSION}
    
ARG UNIFI_VERSION
    
# Ocie
ENV OCIE_CONFIG=/etc/unifi \
    APP_GROUP="root" \
    APP_OWNER="root" \
    APP_DATA=/opt/data \
    APP_HOME=/usr/lib/unifi \
    JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64 \
    UNIFI_VERSION=${UNIFI_VERSION}
    
RUN <<"EOD" bash
    set -eu;
    # Temp Storage
    build="$(mktemp -d)";
    # MongoDB Repo
    wget --quiet "https://www.mongodb.org/static/pgp/server-4.4.asc" -O- | gpg --dearmor -o /usr/share/keyrings/mongodb.gpg;
    echo "deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb.gpg] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/4.4 multiverse" \
        | tee /etc/apt/sources.list.d/mongodb-4.4.list;
    # Unifi Setup
    install -d -m 0755 -o root -g root ${APP_DATA};
    if [[ -z "${UNIFI_VERSION}" ]];then
        UNIFI_VERSION=$(wget --quiet --no-cookies https://dl.ui.com/unifi/debian/dists/stable/ubiquiti/binary-amd64/Packages -O - | sed -n 's/Version: //p');
    fi;
    # Unifi Package
    wget --quiet --no-cookies https://dl.ui.com/unifi/8.0.28/unifi_sysvinit_all.deb -O $build/unifi_sysvinit_all.deb;
    # Libssl Unifi Package
    wget --quiet --no-cookies http://security.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.0g-2ubuntu4_amd64.deb -O $build/libssl1.1_1.1.0g-2ubuntu4_amd64.deb;
    # Add packages
    ocie --pkg "-add binutils,mongodb-org,logrotate,openjdk-17-jre-headless,$build/libssl1.1_1.1.0g-2ubuntu4_amd64.deb,$build/unifi_sysvinit_all.deb";
    # Recreate ../data to /opt/data
    rm -rf ${APP_HOME}/data;
    ln -s ${APP_DATA} ${APP_HOME}/;
    # Cleanup image, remove unused directories and files, etc..
    ocie --clean "-base -dirs $build";
    echo "Finished setting up Unifi Image";
EOD
    
COPY --chown=root:root --chmod=0755 ./src/ ./
    
CMD ["/bin/bash"]
