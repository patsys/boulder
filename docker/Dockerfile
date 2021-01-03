FROM alpine:latest

RUN apk add --no-cache \
  git \
  make \
  musl-dev \
  go

# Configure Go
ENV GOROOT /usr/lib/go
ENV GOPATH /go
ENV PATH /go/bin:$PATH

RUN mkdir -p ${GOPATH}/src ${GOPATH}/bin \
  && git clone https://github.com/letsencrypt/boulder/ $GOPATH/src/github.com/letsencrypt/boulder \
  && cd $GOPATH/src/github.com/letsencrypt/boulder \
  && make


FROM alpine:3  

MAINTAINER Patrick Weber "docker@patweber.de"

LABEL io.k8s.description="Boulder" \ 
      io.k8s.display-name="Boulder"

ENV PATH /opt/boulder/bin:$PATH
ENV INTERNAL_DOMAIN=boulder

RUN apk --no-cache add \
  gettext \
  rsyslog \
  monit

COPY entrypoint.sh /opt/entrypoint
COPY conf/monitrc /etc/monitrc
COPY script/monit-wrapper.sh /opt/monit/monit-wrapper
COPY script/monit-kill.sh /opt/monit/monit-kill

COPY --from=0 /go/src/github.com/letsencrypt/boulder/bin/ /opt/boulder/bin
COPY --from=0 /go/src/github.com/letsencrypt/boulder/test/config /opt/boulder/config
COPY --from=0 /go/src/github.com/letsencrypt/boulder/test/secrets /opt/boulder/config/secrets
COPY --from=0 /go/src/github.com/letsencrypt/boulder/test/grpc-creds /opt/boulder/config/secrets/ca
COPY --from=0 /go/src/github.com/letsencrypt/boulder/test/create_db.sh /opt/boulder/scripts

RUN find /opt/boulder/config  -name "**.json"  -type f -exec sh -c ' \
       sed -i "s|test/secrets/|/opt/boulder/config/secrets/|g" "$0"; \
       sed -i "s|test/grpc-creds/|/opt/boulder/config/secrets/ca/|g" "$0"; \ 
       sed -i "s|test/|/opt/boulder/config/|g" "$0"' {} \; 

ENTRYPOINT ["/opt/entrypoint"]
CMD ["monit","-d","5","-I","-B","-c","/etc/monitrc"]
