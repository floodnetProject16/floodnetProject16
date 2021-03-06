context('Testing FloodnetGraphics')

source(system.file('config', package = 'floodnetRfa'))
library(ggplot2)

test_that('Verifying FloodnetGraphics', {

	##################################
	## AMAX modeling. POT is the same
	###################################

  target0 <- '01AD002'
  da <- AmaxData(DB_HYDAT, target0)
  da <- da[as.integer(format(da$date, '%Y')) > 1926, ]

	xa <- FloodnetAmax(da, nsim = 500, distr = 'pe3', verbose = FALSE)

	expect_equal(xa$site, target0)
	expect_equal(xa$distr, 'pe3')
	expect_equal(xa$method, 'amax')
	expect_equal(xa$thresh, 0)
	expect_equal(xa$ppy, 1)
	expect_equal(xa$period, c(2,5,10,20,50,100))

	sid <- order(da$value)
	expect_equal(da$value[sid], xa$obs)
	expect_equal(da$date[sid], xa$time)
	expect_equal(length(xa$trend), 2)
	expect_equal(length(xa$gof), 1)


	expect_equal(dim(xa$quantile), c(6,4))
	expect_equal(names(xa$quantile), c('pred', 'se', 'lower', 'upper'))

	expect_equal(dim(xa$quantile), c(6,4))
	expect_equal(names(xa$quantile), c('pred', 'se', 'lower', 'upper'))

	expect_equal(dim(xa$param), c(3,2))
	expect_equal(names(xa$param), c('param', 'se'))

	## verify the output table for flood quantile
	xa.tab <- as.data.frame(xa)
  expect_equal(dim(xa.tab), c(24,6))
  expect_equal(colnames(xa.tab), c('site', 'method', 'distribution', 'period',
  																 'variable' ,'value'))

	expect_equal(xa$site, as.character(xa.tab[1,1]))
	expect_equal(xa$distr, as.character(xa.tab$distribution[1]))
	expect_equal(xa$method, as.character(xa.tab$method[1]))
	expect_equal(xa$period, sort(unique(xa.tab$period)))
	expect_equal(xa$quantile[,1], xa.tab$value[1:6])
	expect_equal(xa$quantile[,2], xa.tab$value[7:12])
	expect_equal(xa$quantile[,3], xa.tab$value[13:18])
	expect_equal(xa$quantile[,4], xa.tab$value[19:24])

	## verify the output table for parameters
	xa.tab <- as.data.frame(xa, type = 'param')
  expect_equal(dim(xa.tab), c(6,6))
  expect_equal(colnames(xa.tab), c('site', 'method', 'distribution', 'parameter',
  																 'variable' ,'value'))

	expect_equal(xa$param[,1], xa.tab$value[1:3])
	expect_equal(xa$distr, as.character(xa.tab$distribution[1]))
	expect_equal(xa$method, as.character(xa.tab$method[1]))
	expect_equal(as.character(xa.tab$parameter), rep(c('mu','sigma','gamma'),2))
	expect_equal(xa$param[,1], xa.tab$value[1:3])
  expect_equal(xa$param[,2], xa.tab$value[4:6])


	## Try generating the return level plot and histogram
	plt <- plot(xa, line.args= list(colour = 'red', size = 1),
		 point.args = list(colour = 'blue', size = 3),
		 ribbon.args = list(fill = 'white', colour = 'green'))

	plt <- plot(xa, type = 'qq', line.args= list(colour = 'red', size = 1),
		 point.args = list(colour = 'blue', size = 3),
		 ribbon.args = list(fill = 'white', colour = 'green'))

	plt <- hist(xa, histogram.args = list(fill = 'black', colour = 'green', bins = 12),
		 line.args = list(colour = 'red', size = 2))

	plt <- plot(xa, type = 't', line.args= list(colour = 'red', size = 1),
		 point.args = list(colour = 'blue', size = 3))

  expect_error(plot(xa, 'l'))

  ##################################
	## POT modeling
  ###################################
  dp <- DailyData(DB_HYDAT, target0, pad = TRUE)
	dp <- dp[as.integer(format(dp$date, '%Y')) > 1926, ]

	xp <- FloodnetPot(dp, u = 1000, area = 14073, out.model = TRUE, verbose = FALSE)

	expect_true(is(xp, 'floodnetMdl'))
	expect_true(is(xp$fit, 'fpot'))

	plt <- plot(xp, xlab = 'Return per.', ylab = 'Flood quantiles')
	plt <- plot(xp, type = 'qq')
	plt <- plot(xp, 'h', histogram.args = list(bins = 20))
	plt <- plot(xp, 't')


	##################################
	## Regional modeling
  ###################################
	target.supreg <- with(GAUGEDSITES, supreg_km12[station == target0])
	mysites <- with(GAUGEDSITES, GAUGEDSITES[supreg_km12 == target.supreg, 'station'])

	dr <- AmaxData(DB_HYDAT, mysites, target = target0, size = 10)

	xr <- FloodnetPool(dr, target = target0, tol.H = Inf, verbose = FALSE)

	plt <- plot(xr)
	plt <- plot(xr, type = 'qq')
	plt <- plot(xr, 'h')
	plt <- plot(xr, 't')

	# Customized plot
	## Note the testing of the argument "color" and not colour
	plt <- plot(xr, type = 'l',
							point.args = list(color = 'orange', shape = 'x', size = 4),
		 					average.args = list(color = 'cyan', size = 4),
		 					line.args = list(size = 1.2, linetype = 3),
		 					xlab = 'LSK', ylab = 'LSR') +
	scale_shape_discrete(name = 'SITE') +
	scale_color_brewer(type = 'qual', palette = 'Set3', name = 'Distribution',
										 labels = c('GEV','GLO','GNO','PE3')) +
	theme_dark()

	########################################################
	## Data.frame containing the threshold and drainage area
	info <- GAUGEDSITES[GAUGEDSITES$station %in% mysites, c('station','ppy200','area')]

	## Reading daily peaks
	ds <- DailyPeaksData(DB_HYDAT, info, target = target0, pad = TRUE, size = 10)

	xs <- FloodnetPool(ds, target = target0, verbose = FALSE, tol.H = Inf)

	plt <- plot(xs)
	plt <- hist(xs)
	expect_error(plot(xs, type = 'l'))

	mlst <- CompareModels(xa,xp,xr,xs)

	plt <- plot(mlst) + scale_fill_brewer(type = 'div', palette = 'Spectral') +
		theme(legend.position = 'bottom') + xlab('Return')

	plt <- plot(mlst, type = 'cv', ylab = 'RL', xlab = 'RP') + theme_dark() +
		scale_color_brewer(type = 'qual', palette = 'Set1') +
		theme(legend.position = 'bottom')


	#######################################
	## Seasonal plot
	#######################################
	ss <- GAUGEDSITES[,c('season_angle','season_radius', 'supreg_km6')]
	colnames(ss) <- c('theta', 'rad', 'Region')
	ss$Region <- as.factor(ss$Region)

	plt <- SeasonPlot(xlab = 'theta', ylab = 'rad') +
		geom_point(data = ss[-11,], aes(x = theta, y = rad, colour = Region)) +
		geom_point(data = ss[1,], aes(x = theta, y = rad), size = 3, colour = 'black') +
		theme_minimal()

	######################################
	# Basic map of canada
	######################################

	coord <- GAUGEDSITES[,c('lon','lat','supreg_km6')]
	coord$region <- as.character(coord$supreg_km6)


	suppressMessages(plt <- MapCA(polygon.args = list(colour = 'grey4', fill = 'white')) +
		geom_point(data = coord, aes(x = lon, y = lat, colour = region)) +
		theme_minimal() + scale_color_brewer(type = 'qual', palette = 'Spectral') +
		xlab('Longitude') + ylab('Latitude'))
})
