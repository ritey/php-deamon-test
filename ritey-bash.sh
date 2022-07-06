#!/bin/bash

{

while getopts k: flag
do
    case "${flag}" in
        k) APIKEY=${OPTARG};;
    esac
done

if [ -z "$APIKEY" ]; then
    echo "No API key provided, your API key can be found in your https://ritey.com account."
    exit 0;
fi

sudo rm -R /srv/www/ritey

if [ ! -d "/srv/www" ]; then
sudo mkdir "/srv/www"
sudo chmod +x "/srv/www"
fi

if [ ! -d "/srv/www/ritey" ]; then
sudo mkdir "/srv/www/ritey"
sudo chmod +x "/srv/www/ritey"
fi

cat <<EOF > /srv/www/ritey/ritey2.sh
#!/bin/bash

allLogFiles () {
    FILES=/var/log/nginx/*

    for f in \$FILES
    do
        #echo \$f
        filename=$(basename "\$f")
        extension="\${filename##*.}"
        filename="\${filename%.*}"
        filesize=\$(stat -c%s "\$f")
        if [ \$filesize ]; then
            curl https://ritey.com/api/logs -H "Authorization: Bearer $APIKEY" -F log=@\$f
        fi

        sleep 5s
    done

    FILES=/var/log/apache2/*
    for f in \$FILES
    do
        #echo \$f
        filename=$(basename "\$f")
        extension="\${filename##*.}"
        filename="\${filename%.*}"
        filesize=\$(stat -c%s "\$f")
        if [ \$filesize ]; then
            curl https://ritey.com/api/logs -H "Authorization: Bearer $APIKEY" -F log=@\$f
        fi

        sleep 5s
    done
}

allLogFiles

EOF
cat <<EOF > /srv/www/ritey/ritey.service
[Unit]
Description=Test Daemon Service

[Service]
User=root
Type=simple
TimeoutSec=0
PIDFile=/run/ritey.pid
ExecStart=/bin/bash /srv/www/ritey/ritey2.sh > /dev/null 2>/dev/null
ExecStop=/bin/kill -HUP \$MAINPID
ExecReload=/bin/kill -HUP \$MAINPID
KillMode=process

Restart=on-failure
RestartSec=42s

StandardOutput=null
StandardError=null
[Install]
WantedBy=default.target
EOF

sudo rm /etc/systemd/system/ritey.service
sudo ln -s /srv/www/ritey/ritey.service /etc/systemd/system/ritey.service
#sudo systemctl start ritey
sudo systemctl daemon-reload
sudo systemctl start ritey


}
