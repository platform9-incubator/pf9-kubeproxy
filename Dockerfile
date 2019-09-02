FROM ubuntu:xenial
RUN apt -y update
RUN apt -y install openssl ca-certificates iptables conntrack
COPY kube-proxy /
ENTRYPOINT ["/kube-proxy"]

