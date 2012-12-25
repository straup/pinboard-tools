<?php

	define(ROOT, dirname(__FILE__) . "/");
	define(LIB, ROOT . "lib/");

	define(FPDF, LIB . "fpdf16/");
	define(QR, LIB . "qr/");
	define(FLAMEWORK, LIB . "flamework/");

	require_once(FPDF . "fpdf.php");
	require_once(QR . "qr.php");
	require_once(FLAMEWORK . "lib_flamework.php");

	require_once(LIB . "twPDF.php");

	# FIX ME: is this even necessary?
	date_default_timezone_set('America/Los_Angeles');

	#########################################################

	main();
	exit();

	#######################################################

	function main(){

		$spec = array(
			"output" => array("flag" => "o", "required" => 1, "help" => "The path for the final PDF file you're creating."),
			"username" => array("flag" => "u", "required" => 0, "help" => "The username of the person whose Tweets you're creating a book of. Unfortunately this information is not store in individual Tweets so you need to define it explicitly if you want it to appear in the book."),
			"year" => array("flag" => "y", "required" => 0, "help" => "The year of Tweets you're created a book of. Defaults to the current year."),
		);

		$opts = cli_getopts($spec);

		if (! isset($opts['year'])){
			$opts['year'] = date('Y', time());
		}

		$tweets = fetch_tweets_from_solr($opts);

		$tw = new twPDF($opts);
		$tw->draw($tweets);

		echo "- done -\n";
		return 1;
	}

	#######################################################

	function fetch_tweets_from_solr($opts){

		$tweets = array();

		$parts = array(
			"created_at:[ {$opts['year']}-01-01T00:00:00Z TO {$opts['year']}-12-31T23:59:59Z ]",
			"favorited:false",
		);

		if ($user = $opts['username']){
			$parts[] = "username:{$user}";
		}

		$page = 1;
		$per_page = 1000;
		$page_count = null;

		while ((! isset($page_count)) || ($page <= $page_count)){

			$params = array(
				'q' => implode(" AND ", $parts),
			);

			$more = array(
				'solr_endpoint' => 'http://localhost:8983/solr/twitter/',
				'per_page' => $per_page,
				'page' => $page,
			);

			$rsp = solr_select($params, $more);

			if (! $rsp['ok']){
				break;
			}

			if (! isset($page_count)){
				$page_count = $rsp['pagination']['page_count'];
			}

			$tweets = array_merge($tweets, $rsp['rows']);
			$page += 1;
		}

		return $tweets;
	}

?>
