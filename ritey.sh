#!/bin/bash

{ # this ensures the entire script is downloaded #

sudo rm -R /srv/www/ritey

if [ ! -d "/srv/www/ritey" ]; then
mkdir "/srv/www/ritey"
fi

cat <<EOF > /srv/www/ritey/ritey.php
<?php
gc_enable();

function allLogFiles()
{
    \$files = [];
    if (filesize('/etc/nginx/nginx.conf') && is_dir('/var/log/nginx/')) {
        \$nginx_log_files = scandir('/var/log/nginx/');
        foreach (\$nginx_log_files as \$file) {
            if (strpos(\$file, '.log') && !strpos(\$file, '.gz')) {
                \$files[] = '/var/log/nginx/'.\$file;
            }
        }

    }
    if (filesize('/etc/apache2/apache2.conf') && is_dir('/var/log/apache2/')) {
        \$apache_log_files = scandir('/var/log/apache2/');
        foreach (\$apache_log_files as \$file) {
            if (strpos(\$file, '.log') && !strpos(\$file, '.gz')) {
                \$files[] = '/var/log/apache2/'.\$file;
            }
        }

    }
    
    return \$files;
}

function send(\$uri, \$params)
{
    if (function_exists('curl_init')) {
        \$ch = curl_init(\$uri);
        curl_setopt(\$ch, CURLOPT_POST, true);
        if (!empty(\$params)) {
            curl_setopt(\$ch, CURLOPT_POSTFIELDS, \$params);
        }
        curl_setopt(\$ch, CURLOPT_HTTPHEADER, ['Content-Type:application/json']);
        curl_setopt(\$ch, CURLOPT_RETURNTRANSFER, true);
        \$data = curl_exec(\$ch);
        curl_close(\$ch);
    } else {
        die('Curl is not installed.');
    }

    return \$data;
}

function postFile(\$uri, \$params = [])
{   
    \$file_url = \$params['file'];  //here is the file route, in this case is on same directory but you can set URL too like "http://examplewebsite.com/test.txt"
    \$eol = "\r\n"; //default line-break for mime type
    \$BOUNDARY = md5(time()); //random boundaryid, is a separator for each param on my post curl function
    \$BODY=""; //init my curl body
    \$BODY.= '--'.\$BOUNDARY. \$eol; //start param header
    \$BODY .= 'Content-Disposition: form-data; name="sometext"' . \$eol . \$eol; // last Content with 2 \$eol, in this case is only 1 content.
    \$BODY .= "Some Data" . \$eol;//param data in this case is a simple post data and 1 \$eol for the end of the data
    \$BODY.= '--'.\$BOUNDARY. \$eol; // start 2nd param,
    \$BODY.= 'Content-Disposition: form-data; name="log"; filename="log.txt"'. \$eol ; //first Content data for post file, remember you only put 1 when you are going to add more Contents, and 2 on the last, to close the Content Instance
    \$BODY.= 'Content-Type: application/octet-stream' . \$eol; //Same before row
    \$BODY.= 'Content-Transfer-Encoding: base64' . \$eol . \$eol; // we put the last Content and 2 \$eol,
    \$BODY.= chunk_split(base64_encode(file_get_contents(\$file_url))) . \$eol; // we write the Base64 File Content and the \$eol to finish the data,
    \$BODY.= '--'.\$BOUNDARY .'--' . \$eol. \$eol; // we close the param and the post width "--" and 2 \$eol at the end of our boundary header.

    \$bearer = 'Authorization: Bearer lw0fFdrYzrNuJxBu4arUU7TJoP6p3CYv9kQW6MW9';
    \$ch = curl_init(); //init curl
    curl_setopt(\$ch, CURLOPT_HTTPHEADER, array(
                        \$bearer,
                        'X_PARAM_TOKEN : 71e2cb8b-42b7-4bf0-b2e8-53fbd2f578f9' //custom header for my api validation you can get it from \$_SERVER["HTTP_X_PARAM_TOKEN"] variable
                        ,"Content-Type: multipart/form-data; boundary=".\$BOUNDARY) //setting our mime type for make it work on \$_FILE variable
                );
    curl_setopt(\$ch, CURLOPT_USERAGENT, 'Mozilla/1.0 (Windows NT 6.1; WOW64; rv:28.0) Gecko/20100101 Firefox/28.0'); //setting our user agent
    curl_setopt(\$ch, CURLOPT_URL, \$uri); //setting our api post url
    // curl_setopt(\$ch, CURLOPT_COOKIEJAR, \$BOUNDARY.'.txt'); //saving cookies just in case we want
    curl_setopt (\$ch, CURLOPT_RETURNTRANSFER, 1); // call return content
    curl_setopt (\$ch, CURLOPT_FOLLOWLOCATION, 1); // navigate the endpoint
    curl_setopt(\$ch, CURLOPT_POST, true); //set as post
    curl_setopt(\$ch, CURLOPT_POSTFIELDS, \$BODY); // set our \$BODY

    \$response = curl_exec(\$ch); // start curl navigation

    print_r(\$response); //print response

}

\$files = allLogFiles();

while (!connection_aborted() || PHP_SAPI == 'cli') {

    /*
     \$filename = '/srv/www/ritey/ritey-temp-file.txt';

    if (!file_exists(\$filename)) {
        file_put_contents(\$filename,time().'-'.\$count."\n\n".print_r(allLogFiles(),true));
    } else {
        unlink(\$filename);
    }
    */

    if (count(\$files)) {
        foreach(\$files as \$file) {
            if (filesize(\$file)) {
                postfile('http://wafhub.local/api/logs', ['file' => \$file]);
            }
        }
    }

    sleep(20); // 20 seconds sleep

    if (PHP_SAPI == 'cli') {
        if (0 == rand(5, 100) % 5) {
            gc_collect_cycles(); // Forces collection of any existing garbage cycles
        }
    }
}
EOF

cat <<EOF > /srv/www/ritey/ritey.service
[Unit]
Description=Test Daemon Service

[Service]
User=root
Type=simple
TimeoutSec=0
PIDFile=/run/ritey.pid
ExecStart=/usr/bin/php -f /srv/www/ritey/ritey.php > /dev/null 2>/dev/null
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

cat <<EOF > /srv/www/ritey/ritey-temp-file.txt

EOF

#sudo chmod 755 -R /srv/www/ritey
sudo chown -R www-data:www-data /srv/www/ritey
sudo find /srv/www/ritey -type f -exec chmod 664 {} \;
#sudo chmod 755 -R /srv/www/ritey/ritey.php
sudo find /srv -type d -exec chmod 775 {} \;

sudo rm /etc/systemd/system/ritey.service
sudo ln -s /srv/www/ritey/ritey.service /etc/systemd/system/ritey.service
#sudo systemctl start ritey
sudo systemctl daemon-reload
sudo systemctl start ritey
}