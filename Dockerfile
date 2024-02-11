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
    . /etc/environment;
    # Temp Storage
    build="$(mktemp -d)";
    # MongoDB Repo
    if [[ "${OS_CODENAME}" == "jammy" ]];then
        echo "Ocie: Detected [ jammy:22.04 ], using [ focal:20.04 ] for some packages since Unifi requires MongoDB 4.4.x";
        echo "Ocie: The following packages will be downloaded from:";
        echo "Package: libssl1.1, URL: http://security.ubuntu.com/ubuntu/pool/main/o/openssl";
        echo "Package: mongodb, : URL: https://repo.mongodb.org/apt/ubuntu/dists/focal";
    fi;
    wget --quiet "https://www.mongodb.org/static/pgp/server-4.4.asc" -O- | gpg --dearmor -o /usr/share/keyrings/mongodb.gpg;
    echo "deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb.gpg] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/4.4 multiverse" \
        | tee /etc/apt/sources.list.d/mongodb-4.4.list;
    # Unifi Setup
    install -d -m 0755 -o root -g root ${APP_DATA};
    if [[ -z "${UNIFI_VERSION}" ]];then
        UNIFI_VERSION=$(wget --quiet --no-cookies https://dl.ui.com/unifi/debian/dists/stable/ubiquiti/binary-amd64/Packages -O - | sed -n 's/Version: //p');
    fi;
    # Unifi Installer
    wget --quiet --no-cookies https://dl.ui.com/unifi/${UNIFI_VERSION%%-*}/unifi_sysvinit_all.deb -O $build/unifi_sysvinit_all.deb;
    # Package List
    addpkgs="binutils,mongodb-org,logrotate,openjdk-17-jre-headless,$build/unifi_sysvinit_all.deb";
    # 22.04 Check
    if [[ "${OS_CODENAME}" == "jammy" ]];then
        wget --quiet --no-cookies http://security.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.0g-2ubuntu4_amd64.deb -O $build/libssl1.1_1.1.0g-2ubuntu4_amd64.deb;
        addpkgs+=",$build/libssl1.1_1.1.0g-2ubuntu4_amd64.deb";
    fi;
    ocie --pkg "-add $addpkgs";
    # Recreate ../data to /opt/data
    rm -rf ${APP_HOME}/data;
    ln -s ${APP_DATA} ${APP_HOME}/;
    # Cleanup image, remove unused directories and files, etc..
    ocie --clean "-base -dirs $build";
    echo "Finished setting up Unifi, Version: ${UNIFI_VERSION%%-*}";
EOD
    
COPY --chown=root:root --chmod=0755 ./src/ ./
    
CMD ["/bin/bash"]
