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
    # Source environment for OS_CODENAME
    . /etc/environment;
    # Add MongoDB Repo
    wget --quiet "https://www.mongodb.org/static/pgp/server-7.0.asc" -O- | gpg --dearmor -o /usr/share/keyrings/mongodb.gpg;
    echo "deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb.gpg] https://repo.mongodb.org/apt/ubuntu ${OS_CODENAME}/mongodb-org/7.0 multiverse" \
        | tee /etc/apt/sources.list.d/mongodb-org-7.0.list;
    # Setup system
    ocie --pkg "-add binutils,mongodb-org,libcap2,logrotate,openjdk-17-jre-headless";
    if [[ -z "${UNIFI_VERSION}" ]];then
        UNIFI_VERSION=$(wget --quiet --no-cookies https://dl.ui.com/unifi/debian/dists/stable/ubiquiti/binary-amd64/Packages -O - | sed -n 's/Version: //p');
    fi;
    wget --quiet --no-cookies https://dl.ui.com/unifi/${UNIFI_VERSION%%-*}/UniFi.unix.zip -O /tmp/unifi.zip;
    unzip -qq /tmp/unifi.zip -d /usr/lib/ && mv /usr/lib/UniFi ${APP_HOME};
    install -d -m 0755 -o root -g root ${APP_DATA};
    ln -s ${APP_DATA} ${APP_HOME}/;
    # Cleanup image, remove unused directories and files, etc..
    ocie --clean "-base -path /tmp/ -pattern '*.zip'";
EOD
    
COPY --chown=root:root --chmod=0755 ./src/ ./
    
ENTRYPOINT ["/usr/sbin/ociectl", "--run"]
