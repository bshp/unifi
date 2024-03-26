#### Unifi Network Server  
    
Unifi Network Console, most of this image is ready, testing has not shown any errors.
    
This build does not define a static VOLUME, Unifi data is stored in /opt/data and you will need to map a volume to this location for persistance, e.g    
````
-v unifi_data:/opt/data
````
    
#### Base OS:    
Ubuntu Server LTS
    
#### Packages:    
Updated weekly from the official upstream Ubuntu LTS image
````
binutils 
ca-certificates 
curl 
gnupg 
jq 
logrotate 
openjdk-17-jre-headless 
openssl 
tzdata 
unzip 
wget 
zip 
````
    
#### External Packages
    
mongodb-org: https://repo.mongodb.org/apt/ubuntu    
unifi: https://dl.ui.com/unifi/debian/dists/stable/ubiquiti/binary-amd64/Packages
    
#### Environment Variables:    
    
see [Ocie Environment](https://github.com/bshp/ocie/blob/main/Environment.md) for more info
    
#### Ports
see [Unifi Ports Ingress](https://help.ui.com/hc/en-us/articles/218506997-UniFi-Network-Required-Ports-Reference)
    
#### Direct:  
````
docker run -v unifi_data:/opt/data -p 8080:8080 -p 8443:8443 -d bshp/unifi:latest
````
#### Custom:  
Add at end of your entrypoint script either of:  
````
/usr/sbin/ociectl --run;
````
````
/usr/bin/java -Dlog4j2.formatMsgNoLookups=true \
  -Dunifi.datadir=/opt/data \
  -Dfile.encoding=UTF-8 \
  -Djava.awt.headless=true \
  -Dapple.awt.UIElement=true \
  -XX:+UseParallelGC \
  -XX:+ExitOnOutOfMemoryError \
  -XX:+CrashOnOutOfMemoryError \
  --add-opens java.base/java.lang=ALL-UNNAMED \
  --add-opens java.base/java.time=ALL-UNNAMED \
  --add-opens java.base/sun.security.util=ALL-UNNAMED \
  --add-opens java.base/java.io=ALL-UNNAMED \
  --add-opens java.rmi/sun.rmi.transport=ALL-UNNAMED \
  -jar ${APP_HOME}/lib/ace.jar start
````
    
#### Build:  
OCIE_VERSION = Uses same Ubuntu version semantics, e.g 22.04, 24.04    
UNIFI_VERSION = Unifi Network Version to build, if omitted, the latest available will be used
````
docker build . --pull --build-arg OCIE_VERSION=22.04 --build-arg UNIFI_VERSION=8.1.113 --tag YOUR_TAG
````
    
