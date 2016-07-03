<?php

$filename = $argv[1];
$lines    = file( $filename, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES );

foreach ($lines as $line) {
    
    $line = trim($line);

    if ( strlen($line) < 2 ) continue;

    if (  ($line{0} == ';') && ($line{1} == ';') ) {
           printf("%s\n", trim(substr($line, 2)));
    }

}

