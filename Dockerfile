FROM php-73-rhel7:latest  
MAINTAINER Eliseo Ramirez

USER root
RUN yum -y install rh-php73-php-xmlrpc.x86_64


ADD moodle-latest-38.tgz /
RUN chmod 777 /moodle-latest-38.tgz

ADD php.ini /opt/app-root/etc/php.ini
COPY run_moodle.sh /

RUN mkdir /opt/app-root/moodledata
RUN chmod 775 /opt/app-root/moodledata
RUN chmod 775 /opt/app-root/src

VOLUME /opt/app-root/moodledata
USER 907
EXPOSE 8080

CMD ["/bin/bash","/run_moodle.sh"]
# Set labels usados en OpenShift para describir el build de la imagen
LABEL io.k8s.description="moodle" \
      io.k8s.display-name="moodle apache redhat " \
      io.openshift.expose-services="8080:http" \
      io.openshift.tags="builder,moodle,apache" \
      io.openshift.min-memory="4Gi" \
      io.openshift.min-cpu="2" \
      io.openshift.non-scalable="false"
