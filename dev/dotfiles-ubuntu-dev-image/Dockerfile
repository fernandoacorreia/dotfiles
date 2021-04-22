FROM ubuntu:20.04

RUN apt-get update
RUN apt-get install -y sudo

RUN useradd -ms /bin/bash -G sudo ubuntu
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
USER ubuntu

RUN mkdir -p /home/ubuntu/.ssh
