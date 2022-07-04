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

if [ ! -d "/srv/www/ritey" ]; then
mkdir "/srv/www/ritey"
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
}
