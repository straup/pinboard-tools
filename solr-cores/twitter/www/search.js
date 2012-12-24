function search_init(){

	$("#query_form").submit(function(){
		var query = $("#query").val();

		if (query){
			var args = {'q': query};
			search(args);
		}

		return false;
	});
}

function search(args){

	args['rows'] = 50;
	args['sort'] = 'created_at desc';

	var solr_endpoint = 'http://localhost:8983/solr/twitter/select';

	$.ajax({
		url: solr_endpoint,
		data: args,
		success: search_callback,
		dataType: 'jsonp',
		jsonp: 'json.wrf'
	});

	$("#results").html("");
}

function search_callback(rsp){

	var response = rsp['response'];
	var total = response['numFound'];

	if (total == 0){
		$("#results").html("nothin...");
		return;
	}

	search_draw_results(response);
	return;
}

function search_draw_results(response){

	var total = response['numFound'];

	var docs = response['docs'];
	var count = docs.length;

	// fix me: query term and htmlspecialchars.js

	var html = total + ' results for <q>' + '</q>';
	html += '<ul id="search_results">';

	for (var i=0; i < count; i++){
		var tweet = docs[i];
		var classes = [];

		if (tweet['favorited']){
			classes.push('fave');
		}

		classes = classes.join(' ');

		var link = 'https://www.twitter.com/' + tweet['username'] + '/status/' + tweet['id'];

		var ymd = tweet['created_at'].split('T')[0];

		html += '<li class="' + classes + '">';
		html += '<q>' + tweet['text'] + '</q>';
	    	html += '<div class="meta">';

		if (! tweet['favorited']){	    
			html += '@' + tweet['username'] + ' <a href="' + link + '" target="_twitter">said this</a>';
		}

		else {
			html += ' @' + tweet['username'] + ' faved this';
		}

		html += ' / ' + ymd;
		html += '</div>';
		html += '</li>';
	}

	html += '</ul>';

	$("#results").html(html);
	return;
}
