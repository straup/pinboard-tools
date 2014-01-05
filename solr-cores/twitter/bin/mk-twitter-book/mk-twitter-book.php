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
			"username" => array("flag" => "u", "required" => 0, "help" => "The username of the person whose tweets you're creating a book of."),
			"year" => array("flag" => "y", "required" => 0, "help" => "The year of tweets you're created a book of. Defaults to the current year."),
			"solr" => array("flag" => "s", "required" => 0, "help" => "The Solr endpoint where your tweets are stored. Defaults to http://localhost:8983/solr/twitter/."),
			"exclude-retweets" => array("flag" => "t", "required" => 0, "help" => "Exclude anything that was retweeted from another user"),
			"exclude-replies" => array("flag" => "r", "required" => 0, "help" => "Exclude anything that was a direct reply to a tweet by another user"),
		);

		$opts = cli_getopts($spec);

		if (! isset($opts['year'])){
			$opts['year'] = date('Y', time());
		}

		if (! isset($opts['solr'])){
			$opts['solr'] = 'http://localhost:8983/solr/twitter/';
		}

		$tweets = fetch_tweets_from_solr($opts);

		$tw = new twPDF($opts);
		$tw->draw($tweets);

		echo "- done -\n";
		return 1;
	}

	#######################################################

	function fetch_tweets_from_solr($opts, $more=array()){

		$defaults = array(
			'include_epilogue' => 1,
		);

		$more = array_merge($defaults, $more);

		$date_range = "[ {$opts['year']}-01-01T00:00:00Z TO {$opts['year']}-12-31T23:59:59Z ]";

		$parts = array(
			"created_at" => $date_range,
			"favorited" => "false",
		);

		if ($user = $opts['username']){
			$parts['username'] = $user;
		}

		$tweets = array();

		$page = 1;
		$per_page = 1000;
		$page_count = null;

		while ((! isset($page_count)) || ($page <= $page_count)){

			$query = array();

			foreach ($parts as $k => $v){
				$query[] = "{$k}:{$v}";
			}

			if ($opts['exclude-retweets']){
				$query[] = 'retweeted:false';
				$query[] = '-text:RT*';
			}

			if ($opts['exclude-replies']){
				$query[] = '-reply_to_tweet_id:*';
			}

			$params = array(
				'q' => implode(" AND ", $query),
				'sort' => 'created_at asc',
			);

			$_more = array(
				'solr_endpoint' => $opts['solr'],
				'per_page' => $per_page,
				'page' => $page,
			);

			$rsp = solr_select($params, $_more);

			if (! $rsp['ok']){
				break;
			}

			if (! isset($page_count)){
				$page_count = $rsp['pagination']['page_count'];
			}

			$tweets = array_merge($tweets, $rsp['rows']);
			$page += 1;
		}

		if ($more['include_epilogue']){

			$next_year = $opts['year'] + 1;
			$date_range = "[ {$next_year}-01-01T00:00:00Z TO * ]";

			$parts['created_at'] = $date_range;

			$query = array();

			foreach ($parts as $k => $v){
				$query[] = "{$k}:{$v}";
			}

			$params = array(
				'q' => implode(" AND ", $query),
				'sort' => 'created_at asc',
			);

			$_more = array(
				'solr_endpoint' => $opts['solr'],
				'per_page' => 1,
				'page' => 1,
			);

			$rsp = solr_select($params, $_more);

			if (($rsp['ok']) && (count($rsp['rows']))){
				$tweets = array_merge($tweets, $rsp['rows']);
			}
		}

		return $tweets;
	}

?>
