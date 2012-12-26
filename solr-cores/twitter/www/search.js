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

	solr_select(args, search_callback);  
	$("#results").html("");
}

function search_callback(rsp){

	var response = rsp['response'];        
	var header = rsp['responseHeader'];

	var total = response['numFound'];
	var start = response['start'];

	var per_page = header['params']['rows'];

	var page_count = Math.ceil( total / per_page );
	var page = '';

	var pagination = {
		'total_count': total,
		'page': page,
		'per_page': per_page,
		'page_count': page_count,
	};

	rsp['pagination'] = pagination;    
	console.log(pagination);

	search_draw_results(rsp);
	return;
}

function search_draw_results(rsp){

	var header = rsp['responseHeader'];
	var response = rsp['response'];

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
