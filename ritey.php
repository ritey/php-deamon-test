<?php

gc_enable();
while (!connection_aborted() || PHP_SAPI == 'cli') {
    $filename = '/srv/www/ritey-temp-file.txt';

    if (!file_exists($filename)) {
        file_put_contents($filename);
    } else {
        unlink($filename);
    }

    sleep(20); // 20 seconds sleep

    if (PHP_SAPI == 'cli') {
        if (0 == rand(5, 100) % 5) {
            gc_collect_cycles(); // Forces collection of any existing garbage cycles
        }
    }
}
