# Use a base image with Java 11 (required for Jira 9.13.1)
FROM openjdk:11-jdk-slim

LABEL maintainer="yourname@example.com"
ENV JIRA_VERSION=9.13.1
ENV JIRA_HOME=/var/atlassian/application-data/jira
ENV JIRA_INSTALL=/opt/atlassian/jira
ENV JIRA_USER=jira

# Install required packages and supervisor
RUN apt-get update && \
    apt-get install -y curl gosu unzip ca-certificates supervisor && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create user and directories
RUN groupadd -r ${JIRA_USER} && \
    useradd -m -d ${JIRA_HOME} -r -g ${JIRA_USER} ${JIRA_USER} && \
    mkdir -p ${JIRA_HOME} && \
    mkdir -p ${JIRA_INSTALL} && \
    chown -R ${JIRA_USER}:${JIRA_USER} ${JIRA_HOME} ${JIRA_INSTALL}

# Download and extract Jira
RUN curl -Ls https://product-downloads.atlassian.com/software/jira/downloads/atlassian-jira-software-${JIRA_VERSION}.tar.gz | \
    tar -xz -C /opt/atlassian && \
    mv /opt/atlassian/atlassian-jira-software-${JIRA_VERSION}-standalone ${JIRA_INSTALL} && \
    chown -R ${JIRA_USER}:${JIRA_USER} ${JIRA_INSTALL}

# Setup Jira home
RUN mkdir -p /opt/atlassian/jira/WEB-INF/classes && \
    echo -e "\njira.home=/var/atlassian/application-data/jira" > /opt/atlassian/jira/WEB-INF/classes/jira-application.properties

# Supervisor config
RUN mkdir -p /etc/supervisor/conf.d
COPY jira-supervisord.conf /etc/supervisor/conf.d/jira.conf

# Set permissions again just to be safe
RUN chown -R ${JIRA_USER}:${JIRA_USER} ${JIRA_HOME} ${JIRA_INSTALL}

# Expose ports (standard Jira port and Hazelcast cluster port)
EXPOSE 8080 5701

# Volume for Jira home
VOLUME ["${JIRA_HOME}"]

# Use Supervisor to run Jira
CMD ["/usr/bin/supervisord", "-n"]
