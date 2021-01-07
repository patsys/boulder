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
  && make \
  && go get bitbucket.org/liamstask/goose/cmd/goose \
  && go get github.com/jsha/minica


FROM alpine:3  

MAINTAINER Patrick Weber "docker@patweber.de"

LABEL io.k8s.description="Boulder" \ 
      io.k8s.display-name="Boulder"

ENV PATH /opt/boulder/bin:$PATH
ENV INTERNAL_DOMAIN=boulder \
   INTERMEDIATE_COMMON_NAME="test intermediate" \
   DB_MIGRATE_USER=root \
   DB_HOST=boulder-mysql \
   DB_PORT=3306 \
   DB_ENVS="test \
   integration" \
   DB_CLEAN_INIT=false \
   ENVIRONMENT="" \
   AKAMAI_SECRET=very-secret

RUN apk --no-cache add \
  gettext \
  rsyslog \
  monit \
  softhsm \
  mysql-client

COPY entrypoint.sh /opt/entrypoint
COPY conf/monit/* /opt/boulder/template/monit/
COPY script/monit-wrapper.sh /opt/monit/monit-wrapper
COPY script/monit-kill.sh /opt/monit/monit-kill
COPY script/monit-port-check.sh /opt/monit/monit-check-port
COPY script/migrate.sh /opt/boulder/migrate
COPY script/create_pki.sh /opt/boulder/create_pki

COPY --from=0 /go/bin/ /opt/boulder/bin
COPY --from=0 /go/src/github.com/letsencrypt/boulder/bin/ /opt/boulder/bin
COPY --from=0 /go/src/github.com/letsencrypt/boulder/test/config /opt/boulder/config
COPY --from=0 /go/src/github.com/letsencrypt/boulder/test/secrets /opt/boulder/config/secrets
COPY --from=0 /go/src/github.com/letsencrypt/boulder/test/grpc-creds /opt/boulder/config/secrets/ca
COPY --from=0 /go/src/github.com/letsencrypt/boulder/test/*.json /opt/boulder/config/
COPY --from=0 /go/src/github.com/letsencrypt/boulder/test/*.yml /opt/boulder/config/
COPY --from=0 /go/src/github.com/letsencrypt/boulder/test/*.yaml /opt/boulder/config/
COPY --from=0 /go/src/github.com/letsencrypt/boulder/test/*.pem /opt/boulder/config/
COPY --from=0 /go/src/github.com/letsencrypt/boulder/test/*.key /opt/boulder/config/
COPY --from=0 /go/src/github.com/letsencrypt/boulder/test/*.der /opt/boulder/config/
COPY --from=0 /go/src/github.com/letsencrypt/boulder/sa/_db /opt/boulder/sql/_db
COPY --from=0 /go/src/github.com/letsencrypt/boulder/sa/_db-next /opt/boulder/sql/_db-next
COPY --from=0 /go/src/github.com/letsencrypt/boulder/test/sa_db_users.sql /opt/boulder/sql/
COPY --from=0 /go/src/github.com/letsencrypt/boulder/test/cert-ceremonies /opt/boulder/cert-ceremonies
COPY --from=0 /go/src/github.com/letsencrypt/boulder/test/wfe-tls /opt/boulder/config/wfe-tls
COPY --from=0 /go/src/github.com/letsencrypt/boulder/test/mail-test-srv/localhost/*.pem /opt/boulder/config/secrets/ca/mail-test-srv/
COPY --from=0 /go/src/github.com/letsencrypt/boulder/test/*-template /opt/boulder/config/
COPY --from=0 /go/src/github.com/letsencrypt/boulder/test/mail-test-srv/*.pem /opt/boulder/config/mail-test-srv/
COPY --from=0 /go/src/github.com/letsencrypt/boulder/test/ct-test-srv/*.json /opt/boulder/config/ct-test-srv/

RUN find /opt/boulder/config  -name "**.json"  -type f -exec sh -c ' \
       sed -i "s|test/secrets/|/opt/boulder/config/secrets/|g" "$0"; \
       sed -i "s|test/grpc-creds/|/opt/boulder/config/secrets/ca/|g" "$0"; \ 
       sed -i "s|test/|/opt/boulder/config/|g" "$0"; \
       sed -i "s|/usr/local/lib/|/usr/lib/|g" "$0"; \
       sed -i "s|/tmp/|/pki/|g" "$0"' {} \; \ 
    && find /opt/boulder/cert-ceremonies/ -name "*.yaml" -type f -exec sh -c ' \
       sed -i "s|/usr/local/lib/|/usr/lib/|g" "$0"; \
       sed -i "s|/tmp/|/pki/|g" "$0"' {} \; \
    && mkdir /pki

ENTRYPOINT ["/opt/entrypoint"]
CMD ["monit","-d","5","-I","-B","-c","/etc/monitrc$ENVIRONMENT"]
