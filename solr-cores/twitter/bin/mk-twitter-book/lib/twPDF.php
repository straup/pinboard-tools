<?php

	class twPDF extends FPDF {

		function twPDF($opts){

			$this->FPDF("P", "in", array(6, 9));

			$this->opts = $opts;

			$this->tweet = null;
			$this->text_align = null;
		}

		function setup_margins(){

			if ($this->PageNo() % 2){
				$this->SetMargins(1.25, 1.5);
				$this->text_align = 'L';
			}

			else {
				$this->SetMargins(1, 1.5);
				$this->SetRightMargin(1.25);
				$this->text_align = 'R';
			}
		}

		function draw($tweets){

			$this->AddPage();
			$this->AddPage();

			$title = "#{$this->opts['year']}";

			$this->AddPage();
			$this->SetRightMargin(1.25);
			$this->SetFont('Helvetica','B', 51);
			$this->SetTextColor(126, 126, 126);
			$this->setY(-2.25);
			$this->MultiCell(0, 1, $title, 0, 'R');

			$this->SetFont('Helvetica','B', 18);
			$this->MultiCell(0, 0, $this->opts['username'], 0, 'R');

			$this->AddPage();

			$pages = array();
			$index = array();

			foreach ($tweets as $tw){

				$this->tweet = $this->parse($tw);

				if (! $this->tweet){
					continue;
				}

				if ($this->tweet['epilogue']){

					if ($this->PageNo() % 2){
						$this->addPage();
					}

					$this->addPage();
					$this->addPage();

					$this->addPage();
					$this->SetTextColor(0);
					$this->SetMargins(1, 1);
					$this->SetY(-2);
					$this->SetX(3);
					$this->SetFont('Helvetica', 'B', 24);
					$this->MultiCell(2, .2, "#epilogue", 0, 'L');

					$this->AddPage();
				}

				$this->setup_margins();
				$this->AddPage();

				$this->SetFont('Helvetica','B', 24);
				$this->SetTextColor(0);

				$text = $this->tweet['text'];
				$this->MultiCell(0, .5, $text, 0, $this->text_align);

				$qr_img = $this->generate_qrcode($this->tweet['url']);

				$qr_pos = -2.25;
				$dt_pos = -1.25;

				$this->setY($qr_pos);

				if ($this->text_align == 'R'){
					$this->setX(-2.20);
				}

				else {
					$this->setX(1.2);
				}

				$this->Image($qr_img, null, null, 1, 1);
				unlink($qr_img);

				$this->SetY($dt_pos);

				$this->SetFont('Helvetica','B', 10);
				$this->SetTextColor(126, 126, 126);
				$this->MultiCell(0, .25, $this->tweet['date'], 0, $this->text_align);

				if ($this->tweet['epilogue']){
					break;
				}
			}

			$this->draw_colophon($this->opts['username']);

			$this->Output($this->opts['output']);
		}

		function generate_qrcode($text){

			$qr_args = array(
				'data' => QR . "data",
				'images' => QR . "image"
			);

			$enc = md5($text);
			$qr_img_black = tempnam("/tmp", time()) . "qr-{$enc}.png";

			$qr = new QR($qr_args);

			$args = array(
				'd' => $text,
				'path' => $qr_img_black,
			);

			$qr->encode($args);

			$im_black = imagecreatefrompng($qr_img_black);
			imagecolorset($im_black, 1, 126, 126, 126);
			imagepng($im_black, $qr_img_black);

			return $qr_img_black;
		}

		function draw_colophon($name=''){

			if ($name == ''){
				return;
			}

			if ($this->PageNo() % 2){
				$this->addPage();
			}

			$this->addPage();
			$this->addPage();

			$this->addPage();
			$this->SetTextColor(0);
			$this->SetMargins(1, 1);
			$this->SetY(-2);
			$this->SetX(3);
			$this->SetFont('Helvetica', 'B', 12);
			$this->MultiCell(2, .2, "this is a thing made by {$name}", 0, 'R');
		}

		function parse($data){

			$date = strtotime($data['created_at']);

			$year = date("Y", $date);
			$ymd = date("F d, Y", $date);

			if ($year < $this->opts['year']){
				return null;
			}

			$text = html_entity_decode($data['text']);
			$text = iconv("UTF-8", "ISO-8859-1//TRANSLIT", $text);
			$text = trim($text);

			$id = $data['id'];

			$rsp = array(
				'id' => $id,
				'url' => "http://twitter.com/{$data['username']}/status/{$id}",
				'date' => $ymd,
				'text' => $text,
			);

			if ($year > $this->opts['year']){
				$rsp['epilogue'] = 1;
			}

			return $rsp;
		}

	}
