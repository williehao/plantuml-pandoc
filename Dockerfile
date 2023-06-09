FROM maven:3-jdk-11-slim AS builder

COPY pom.xml /app/
COPY src/main /app/src/main/

WORKDIR /app
RUN mvn --batch-mode --define java.net.useSystemProxies=true -Dapache-jsp.scope=compile package
########################################################################################

FROM tomcat:10-jdk11-openjdk-slim

RUN apt-get update  && \
    apt-get install -y --no-install-recommends \
        fonts-noto-cjk \
        graphviz \
        python3-pip \
        pandoc \
        && \
    rm -rf /var/lib/apt/lists/*

RUN pip3 install pandoc-plantuml-filter

RUN apt update
RUN apt install -y plantuml
RUN apt install -y texlive

COPY docker-entrypoint.tomcat.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENV WEBAPP_PATH=$CATALINA_HOME/webapps
RUN rm -rf $WEBAPP_PATH && \
    mkdir -p $WEBAPP_PATH
COPY --from=builder /app/target/plantuml.war /plantuml.war

ENTRYPOINT ["/entrypoint.sh"]
CMD ["catalina.sh", "run"]
# Openshift https://docs.openshift.com/container-platform/4.9/openshift_images/create-images.html#images-create-guide-openshift_create-images
USER root
RUN chgrp -R 0 $CATALINA_HOME &&  chmod -R g=u $CATALINA_HOME
