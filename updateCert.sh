#! /bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

DOMAIN=`ls .acme.sh/*_ecc/*.key|sed 's#/#\n#g'|grep .key|sed 's/.key//g'`
echo "The domain is : ${DOMAIN}"
service caddy stop
sleep 2s
~/.acme.sh/acme.sh --renew --force --ecc -d ${DOMAIN}
sleep 2s
service caddy start
