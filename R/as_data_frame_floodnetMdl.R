#' @export
#' @rdname floodnetMdl
as.data.frame.floodnetMdl <-
	function(x,
					 row.names = NULL,
					 optional = FALSE,
					 type = 'q',
					 ...){

	## Melting the data
	if(type %in% c('q', 'quantile', 'flood')){
		x0 = as.numeric(as.matrix(x$quantile))
		lab <- expand.grid(period = x$period, variable = c('quantile','se','lower','upper'))

	} else if(type %in% c('p', 'param' )){
		x0 = as.numeric(as.matrix(x$param))
		lab <- expand.grid(parameter = row.names(x$param), variable = c('par','se'))

	}

	ans <- data.frame(site = x$site,
										method = x$method,
										distribution = x$dist,
										lab,
										value = x0)

	if(optional){
		rownames(ans) <- make.names(rownames(ans))
	}

	return(ans)
}

#' @export
#' @rdname floodnetMdl
as.data.frame.floodnetMdls <-
	function(x,
					 row.names = NULL,
					 optional = FALSE,
					 type = 'q', ...){

	ans <- lapply(x, as.data.frame, type = type, row.names = row.names,
								optional = optional)
	ans <- do.call(rbind, ans)

	return(ans)
}
