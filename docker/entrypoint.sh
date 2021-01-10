#!/bin/sh
set -e -o pipefail
find /opt/boulder/config/test  -name "**.json"  -type f -exec sh -c '
  sed -i "s|http://example.com|.$EXTERNAL_DOMAIN|g" "$0"
  sed -i "s|\.boulder|.$INTERNAL_DOMAIN|g" "$0"
  sed -i "s|boulder:|$INTERNAL_DOMAIN:|g" "$0"' {} \; 

for monit in /opt/boulder/template/monit/*; do
  envsubst <$monit >/etc/$(basename $monit)
  chmod 700 /etc/$(basename $monit)
done
IFS="
" for config in find /opt/boulder/template/config/ -type f -printf "%P\n"; do
  mkidr -p "/opt/boulder/config/$(dirname $config)"
  envsubst <"/opt/boulder/template/config/$config" >"/opt/boulder/config/$config"
done
mkdir -p /opt/grpc-health-proxy/config/boulder
for proxy in /opt/boulder/template/grpc-health-proxy/*; do
  envsubst <$proxy >/opt/grpc-health-proxy/config/boulder/$(basename $proxy)
  chmod 700 /etc/$(basename $monit)
done

cat /opt/boulder/config/test/secrets/ca/health-checker.boulder/cert.pem /opt/boulder/config/test/secrets/ca/health-checker.boulder/key.pem > /opt/boulder/config/test/secrets/ca/health-checker.boulder/monit.pem

wait_tcp_port() {
    local host="$1" port="$2"

    # see http://tldp.org/LDP/abs/html/devref1.html for description of this syntax.
    local max_tries="120"
    for n in `seq 1 $max_tries` ; do
      if nc -z -w5 $host $port; then
        break
      else
        echo "$(date) - still trying to connect to $host:$port"
        sleep 1
      fi
      if [ "$n" -eq "$max_tries" ]; then
        echo "unable to connect"
        exit 1
      fi
    done
    exec 6>&-
    echo "Connected to $host:$port"
}

wait_pki() {
  local max_tries="90"
  for n in `seq 1 $max_tries` ; do
    if [ $(ls /pki | wc -w ) -ge 8 ]; then
      break
    else
      echo "$(date) - /pki files not exist"
      sleep 2
    fi
    if [ "$n" -eq "$max_tries" ]; then
      echo "unable to find pki"
      exit 2
    fi
  done
}
# make sure we can reach the mysqldb
wait_tcp_port $DB_HOST $DB_PORT

if echo "$ENVIRONMENT" | grep -q "testing"; then
/opt/boulder/create_pki
wait_pki
fi


/opt/boulder/migrate

if [ "$ENVIRONMENT" ]; then
  ENVIRONMENT="-$ENVIRONMENT"
fi
echo $@
eval "$@" | while IFS= read -r line; do echo $(date +'[%Y-%m-%d %H:%M:%S]') $line; done
