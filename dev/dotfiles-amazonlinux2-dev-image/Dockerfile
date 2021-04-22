FROM amazonlinux:2

RUN yum update -y
RUN yum install -y shadow-utils sudo

RUN useradd -ms /bin/bash ec2-user
RUN echo '%ec2-user ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
USER ec2-user

RUN mkdir -p /home/ec2-user/.ssh
