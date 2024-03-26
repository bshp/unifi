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
    APP_VOLS="/opt/data" \
    JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64 \
    UNIFI_VERSION=${UNIFI_VERSION}
    
RUN <<"EOD" bash
    set -eu;
    . /etc/environment;
    # Temp Storage
    build="$(mktemp -d)";
    # MongoDB Repo
    echo "Package: mongodb, URL: https://repo.mongodb.org/apt/ubuntu/dists/${OS_CODENAME}";
    wget --quiet --no-cookies "https://www.mongodb.org/static/pgp/server-6.0.asc" -O- | gpg --dearmor -o /usr/share/keyrings/mongodb.gpg;
    echo "deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb.gpg] https://repo.mongodb.org/apt/ubuntu ${OS_CODENAME}/mongodb-org/6.0 multiverse" \
        | tee /etc/apt/sources.list.d/mongodb-6.0.list;
    # Unifi Setup
    install -d -m 0755 -o ${APP_OWNER} -g ${APP_GROUP} ${APP_DATA};
    if [[ -z "${UNIFI_VERSION}" ]];then
        UNIFI_VERSION=$(wget --quiet --no-cookies https://dl.ui.com/unifi/debian/dists/stable/ubiquiti/binary-amd64/Packages -O - | sed -n 's/Version: //p');
    fi;
    # Unifi Installer
    wget --quiet --no-cookies "https://dl.ui.com/unifi/${UNIFI_VERSION%%-*}/unifi_sysvinit_all.deb" -O $build/unifi_sysvinit_all.deb;
    # Package List
    ocie --pkg "-add binutils,mongodb-org,logrotate,openjdk-17-jre-headless,$build/unifi_sysvinit_all.deb";
    # Recreate ../data to /opt/data
    rm -rf ${APP_HOME}/data;
    ln -s ${APP_DATA} ${APP_HOME}/;
    # Fix logging, -Dunifi.logdir also needed a trailing slash, e.g /var/log/unifi/
    chown -R ${APP_OWNER}:${APP_GROUP} /var/log/unifi && chmod -R 0755 /var/log/unifi; 
    # Cleanup image, remove unused directories and files, etc..
    ocie --clean "-base -dirs $build";
    echo "Finished setting up Unifi, Version: ${UNIFI_VERSION%%-*}";
EOD
    
COPY --chown=root:root --chmod=0755 ./src/ ./
    
CMD ["/bin/bash"]
