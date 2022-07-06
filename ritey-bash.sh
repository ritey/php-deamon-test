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

sudo rm -R /ritey

if [ ! -d "/ritey" ]; then
sudo mkdir "/ritey"
sudo chmod 775 "/ritey"
fi

cat <<EOF > /ritey/ritey2.sh
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
cat <<EOF > /ritey/ritey.service
[Unit]
Description=Test Daemon Service

[Service]
User=root
Type=simple
TimeoutSec=0
PIDFile=/run/ritey.pid
ExecStart=/bin/bash /ritey/ritey2.sh > /dev/null 2>/dev/null
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
sudo ln -s /ritey/ritey.service /etc/systemd/system/ritey.service
#sudo systemctl start ritey
sudo systemctl daemon-reload
sudo systemctl start ritey


}
