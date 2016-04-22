echo -n "Hiding server information: "
    cd $TC_INSTALLBASE/tomcat/lib && jar xf catalina.jar org/apache/catalina/util/ServerInfo.properties
    perl -pi -e 's/server.info=Apache Tomcat\/6.0.35/server.info=Apache/' org/apache/catalina/util/ServerInfo.properties
    jar uf catalina.jar org/apache/catalina/util/ServerInfo.properties
    rm -rf org
    echo "done."
