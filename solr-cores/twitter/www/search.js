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

	var html = total + ' results';
	html += '<ul>';

	for (var i=0; i < count; i++){
		var tweet = docs[i];

		html += '<li>';
		html += tweet['text'];
		html += ' – @' + tweet['username'];
		html += ', ' + tweet['created_at'];
		html += '</li>';
	}

	html += '</ul>';

	$("#results").html(html);
	return;
}
