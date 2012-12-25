<?php

include_once("QR.php");

	$text = "http://m.flickr.com/search/?q=filtr%3Aprocess%3Dheathr&st=rec";
	$path = "/home/asc/Desktop/qr.jpg";

     $qr = new QR(array(
			'data' => dirname(__FILE__) . '/data',
			'images' => dirname(__FILE__) . '/image'
			));

	$qr->encode(array(
			  'd' => $text,
			  'path' => $path,
			  ));

?>