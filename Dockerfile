FROM alpine:latest as certs
RUN apk --no-cache --update upgrade && apk --no-cache add ca-certificates
COPY kube-proxy /
ENTRYPOINT ["/kube-proxy"]

