#!/usr/bin/php
<?php

$inf      = $argv[1];
$ouf      = $argv[2];

$lines    = file( $inf, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES );
$fontbin  = str_repeat('A', 4096);


for ($n = 0; $n <= 0xFF; $n++) {

    $r = array_merge(array_filter(explode(' ', $lines[$n*17])));
    assert( strcmp($r[0], 'char')==0 );
    $a = hexdec($r[1]); 

    //printf("Processing 0x%X-th glyph\n", $a);

    for ($m = 1; $m <= 16; $m++) {

      $r = trim($lines[$n*17+$m]);
      assert(strlen($r) == 8);
      $fontbin{$n*16+$m-1} = char2bin($r);

    }
}

file_put_contents($ouf, $fontbin);

function char2bin($str) {

    $n0 = (int)($str{0} != '.');
    $n1 = (int)($str{1} != '.');
    $n2 = (int)($str{2} != '.');
    $n3 = (int)($str{3} != '.');
    $n4 = (int)($str{4} != '.');
    $n5 = (int)($str{5} != '.');
    $n6 = (int)($str{6} != '.');
    $n7 = (int)($str{7} != '.');

    //$r = $n0 + ($n1<<1) + ($n2<<2) + ($n3<<3) + ($n4<<4) + ($n5<<5) + ($n6<<6) + ($n7<<7);
    $r = ($n0 << 7) + ($n1<<6) + ($n2<<5) + ($n3<<4) + ($n4<<3) + ($n5<<2) + ($n6<<1) + ($n7<<0);

    $r = chr($r);
    return $r;
}


