<?php

include("qr.php");

	$qr = new QR(array(
			   data => './data',
			   images => './image'
			   ));

	$qr->encode(array(
			  'd' => 'http://upcoming.org/event/155488/',
			  'path' => '/home/asc/papers/dwim/img/qr.jpg',
			  ));
