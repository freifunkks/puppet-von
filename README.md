# puppet-vpn
Bevor puppet seine Arbeit machen kann, müssen zuvor folgende Schritte ausgeführt werden.

`apt-get update`
`apt-get install git puppet r10k`
`git clone https://github.com/freifunkks/puppet`
`cd pupppet`
`r10k puppetfile install`
`useradd ffks -m`
und die Datei `/root/fastd_secret_key` muss vorhanden sein.

Nun kann `bin/puppet-apply.sh` aufgerufen werden.
