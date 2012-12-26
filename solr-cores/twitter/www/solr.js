function solr_select(args, callback){

	var page = 2;

	args['rows'] = 50;
	args['sort'] = 'created_at desc';

	args['start'] = args['rows'] * (page - 1);

	var solr_endpoint = 'http://localhost:8983/solr/twitter/select';

	$.ajax({
		url: solr_endpoint,
		data: args,
		success: function(rsp){
			solr_select_callback(rsp, callback);
		},
		dataType: 'jsonp',
		jsonp: 'json.wrf'
	});

}

function solr_select_callback(rsp, callback){

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

	callback(rsp);
	return;
}
