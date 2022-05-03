FROM ubi8/ubi
RUN yum install -y --disablerepo=* --enablerepo=ubi-8-appstream --enablerepo=ubi-8-baseos openssl
