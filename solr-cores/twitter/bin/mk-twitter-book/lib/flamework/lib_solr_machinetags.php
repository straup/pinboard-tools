<?php

	#################################################################

	function solr_machinetags_prepare_for_path_hierarchy_field($mt, $more=array()){

		$defaults = array(
			'add_lazy_8s' => 1,
		);

		$more = array_merge($defaults, $more);

		$parts = solr_machinetags_explode($mt);

		if ($more['add_lazy_8s']){
			$parts = solr_machinetags_lazy8ify_list($parts);
		}

		return implode("/", $parts);
	}

	#################################################################

	function solr_machinetags_prepare_for_multivalue_field($mt, $more=array()){

		$defaults = array(
			'add_lazy_8s' => 1,
		);

		$more = array_merge($defaults, $more);

		list($ns, $pred, $value) = solr_machinetags_explode($mt);

		$parts = array(
			"{$ns}:",
			"{$ns}:{$pred}=",
			"{$ns}:{$pred}={$value}",
			"={$value}",
			":{$pred}=",
			":{$pred}={$value}",
		);

		if ($more['add_lazy_8s']){
			$parts = solr_machinetags_lazy8ify_list($parts);
		}

		return $parts;
	}

	#################################################################

	function solr_machinetags_explode($mt, $more=array()){

		list($ns, $rest) = explode(":", $mt, 2);
		list($pred, $value) = explode("=", $rest, 2);

		return array($ns, $pred, $value);
	}

	#################################################################

	function solr_machinetags_lazy8ify_list(&$parts){

		$enc_parts = array();

		foreach ($parts as $str){
			$enc_stuff[] = solr_machinetags_add_lazy8s($str);
		}

		return $enc_stuff;
	}

	#################################################################

	function solr_machinetags_add_lazy8s($str){
		$str = preg_replace("/8/", "88", $str);
		$str = preg_replace("/:/", "8c", $str);
		$str = preg_replace("/\//", "8s", $str);
		return $str;
	}

	#################################################################

	function solr_machinetags_remove_lazy8s($str){

		$str = preg_replace("/8s/", "/", $str);
		$str = preg_replace("/8c/", ":", $str);
		$str = preg_replace("/88/", "8", $str);

		return $str;
	}

	#################################################################

	function solr_machinetags_inflate_for_path_hierarchy($mt){

		$parts = array();

		foreach (explode("/", $mt, 3) as $str){
			$parts[] = solr_machinetags_remove_lazy8s($str);
		}

		return "{$parts[0]}:{$parts[1]}={$parts[2]}";
	}

	#################################################################

	# Adapted from the building=yes codebase – THIS SHOULD BE CONSIDERED
	# FLAKEY AND NEEDS MORE TESTS, ESPECIALLY FOR WILDCARDS (20121116/straup)

	# things to test with:
	# http://buildingequalsyes.spum.org/tags/gnis:feature_id=2461281
	# http://buildingequalsyes.spum.org/tags/name=Valley%20View%20Library
	# http://buildingequalsyes.spum.org/tags/horse=yes
	# http://buildingequalsyes.spum.org/tags/ele=114 <-- borked, possible to make work w/ literal fq?

	function solr_machinetags_query_for_path_hierarchy($mt, $field, $more=array()){

		list($ns, $pred, $value) = solr_machinetags_explode($mt);

		$k = array();

		if ($ns != '*'){
			$k[] = solr_machinetags_add_lazy8s($ns);
		}

		if ($pred != '*'){
			$k[] = solr_machinetags_add_lazy8s($pred);
		}

		$k = (count($k)) ? implode("/", $k) : '';

		$v = ($v == '*') ? solr_machinetags_add_lazy8s($value) : '';

		$query = array();

		if ($k){
			$query[] = "{$field}:{$k}/*";
		}

		$values = ($value) ? explode(" ", $value) : array();
		$count = count($values);

		for ($i=0; $i < $count; $i++){

			$v = solr_machinetags_add_lazy8s($values[$i]);

			if ($count == 1){
				$q = "{$field}:*/{$v}";
			}

			else if ($i == 0){
				$q = "{$field}:{$k}/{$v}*";
			}

			else if ($i == ($count-1)){
				$q = "{$field}:{$k}/*{$v}";
			}

			else {
				$q = "{$field}:{$k}/*{$v}*";
			}

			$query[] = $q;
		}

		$q = implode(" AND ", $query);
		return $q;
	}

	#################################################################
?>
