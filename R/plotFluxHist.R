#' Graph of annual flux and flow normalized flux versus year
#'
#' @description
#' The annual results reported are for a specified "period of analysis" which can be 
#' an entire water year, a calendar, a season or even an individual month. 
#' The user specifies this period of analysis in the call to setupYears.
#' 
#' Although there are a lot of optional arguments to this function, most are set to a logical default.
#'
#' Data come from named list, which contains a Daily dataframe with the daily flow data,
#' and an INFO dataframe with metadata. 
#'
#' @param eList named list with at least the Daily and INFO dataframes
#' @param yearStart numeric is the calendar year containing the first estimated annual value to be plotted, default is NA (which allows it to be set automatically by the data)
#' @param yearEnd numeric is the calendar year just after the last estimated annual value to be plotted, default is NA (which allows it to be set automatically by the data)
#' @param flowNormYears vector of flow years
#' @param waterYear logical. Should years be water years (\code{TRUE}) or calendar years (\code{FALSE})
#' @param fluxUnit number representing entry in pre-defined fluxUnit class array. \code{\link{printFluxUnitCheatSheet}}
#' @param fluxMax number specifying the maximum value to be used on the vertical axis, default is NA (which allows it to be set automatically by the data)
#' @param printTitle logical variable if TRUE title is printed, if FALSE title is not printed (this is best for a multi-plot figure)
#' @param plotFlowNorm logical variable if TRUE the flow normalized line is plotted, if FALSE not plotted 
#' @param tinyPlot logical variable, if TRUE plot is designed to be plotted small, as a part of a multipart figure, default is FALSE
#' @param cex numerical value giving the amount by which plotting symbols should be magnified
#' @param cex.main magnification to be used for main titles relative to the current setting of cex
#' @param cex.axis magnification to be used for axis annotation relative to the current setting of cex
#' @param col color of points on plot, see ?par 'Color Specification'
#' @param lwd number line width
#' @param customPar logical defaults to FALSE. If TRUE, par() should be set by user before calling this function 
#' (for example, adjusting margins with par(mar=c(5,5,5,5))). If customPar FALSE, EGRET chooses the best margins depending on tinyPlot.
#' @param col.pred color of flow normalized line on plot, see ?par 'Color Specification'
#' @param \dots arbitrary graphical parameters that will be passed to genericEGRETDotPlot function (see ?par for options)
#' @keywords graphics water-quality statistics
#' @export
#' @seealso \code{\link{setupYears}}
#' @examples
#' yearStart <- 2001
#' yearEnd <- 2010
#' eList <- Choptank_eList
#' # Water year:
#' \dontrun{
#' plotFluxHist(eList)
#' plotFluxHist(eList, yearStart, yearEnd, fluxUnit = 1)
#' plotFluxHist(eList, yearStart, yearEnd, fluxUnit = 'kgDay')
#' # Graphs consisting of Jun-Aug
#' eList <- setPA(eList, paStart=6,paLong=3)
#' plotFluxHist(eList) 
#' 
#' # Flow normalized (excluding extremes from 2003-04):
#' yearVector <- c(1980:2002, 2005:2015)
#' plotFluxHist(eList, flowNormYears=yearVector)
#' 
#' #Alternative:
#' sampleSegStart <- c(1980,1985,2000)
#' flowSegStart <- c(1980,1990,2000)
#' flowSegEnd <- c(1990,2000,2010)
#' dateInfo <- data.frame(sampleSegStart,
#'                        flowSegStart,
#'                        flowSegEnd)
#' eList1 <- flexFN(eList, dateInfo)
#' plotFluxHist(eList1)  
#' flexPlotAddOn(eList1)
#' 
#' }
plotFluxHist<-function(eList, yearStart = NA, yearEnd = NA, flowNormYears = "all", 
    waterYear = TRUE, fluxUnit = 9, fluxMax = NA, printTitle = TRUE, 
    plotFlowNorm = TRUE, tinyPlot=FALSE, col="black", col.pred="green",
    cex=0.8, cex.axis=1.1, cex.main=1.1, lwd=2, customPar=FALSE, ...){

  localINFO <- getInfo(eList)
  localDaily <- getDaily(eList)
  
  if(sum(c("paStart","paLong") %in% names(localINFO)) == 2){
    paLong <- localINFO$paLong
    paStart <- localINFO$paStart  
  } else {
    paLong <- 12
    paStart <- 10
  }
  
  if(!all((c("SE","yHat") %in% names(eList$Sample)))){
    stop("This function requires running modelEstimation on eList")
  }
  
  possibleGoodUnits <- c("mg/l","mg/l as N", "mg/l as NO2", 
                         "mg/l as NO3","mg/l as P","mg/l as PO3","mg/l as PO4","mg/l as CaCO3",
                         "mg/l as Na","mg/l as H","mg/l as S","mg/l NH4" )
  
  allCaps <- toupper(possibleGoodUnits)
  localUnits <- toupper(localINFO$param.units)
  
  if(!(localUnits %in% allCaps)){
    warning("Expected concentration units are mg/l, \nThe INFO dataframe indicates:",localINFO$param.units,
            "\nFlux calculations will be wrong if units are not consistent")
  }
  
  if(is.null(attr(eList$INFO,"segmentInfo"))){
    localDaily <- subFN(eList = eList, flowNormYears = flowNormYears, waterYear = waterYear)
  } else {
    localDaily <- eList$Daily
    message("Plotting flow-normalized concentration based on results of flexFN")
  }
  
  localAnnualResults <- setupYears(paStart=paStart,paLong=paLong, localDaily = localDaily)
  
  ################################################################################
  # I plan to make this a method, so we don't have to repeat it in every funciton:
  if (is.numeric(fluxUnit)){
    fluxUnit <- fluxConst[shortCode=fluxUnit][[1]]    
  } else if (is.character(fluxUnit)){
    fluxUnit <- fluxConst[fluxUnit][[1]]
  }
  ################################################################################
  
  
  if (tinyPlot) {
    ylabel <- fluxUnit@unitExpressTiny
  } else {
    ylabel<-fluxUnit@unitExpress
  }
  
  unitFactorReturn <- fluxUnit@unitFactor
#   ylabel <- paste("Flux in ", fluxUnit@unitName, sep="")
  numYears <- length(localAnnualResults$DecYear)
  yearStart <- if(is.na(yearStart)) trunc(localAnnualResults$DecYear[1]) else yearStart
  yearEnd <- if(is.na(yearEnd)) trunc(localAnnualResults$DecYear[numYears])+1 else yearEnd
  subAnnualResults<-localAnnualResults[localAnnualResults$DecYear>=yearStart & localAnnualResults$DecYear <= yearEnd,]
  
  annFlux<-unitFactorReturn*subAnnualResults$Flux
  fnFlux<-unitFactorReturn*subAnnualResults$FNFlux

  periodName<-setSeasonLabel(localAnnualResults=localAnnualResults)
  title3<-if(plotFlowNorm) "\nFlux Estimates (dots) & Flow Normalized Flux (line)" else "\nAnnual Flux Estimates"
  title<-if(printTitle) paste(localINFO$shortName," ",localINFO$paramShortName,"\n",periodName,title3) else ""
  
  xInfo <- generalAxis(x=subAnnualResults$DecYear, minVal=yearStart, maxVal=yearEnd,padPercent=0, tinyPlot=tinyPlot)  
  
  combinedY <- c(annFlux,fnFlux)
  yInfo <- generalAxis(x=combinedY, minVal=0, maxVal=fluxMax, padPercent=5, tinyPlot=tinyPlot)
  
  ###############################################
  
  genericEGRETDotPlot(x=subAnnualResults$DecYear, y = annFlux,
                      xTicks=xInfo$ticks, yTicks=yInfo$ticks,xDate=TRUE,
                      xlim=c(xInfo$bottom,xInfo$top), ylim=c(0,yInfo$top),col=col,
                      ylab=ylabel, plotTitle=title, customPar=customPar,cex=cex,
                      cex.axis=cex.axis,cex.main=cex.main, tinyPlot=tinyPlot,...
                      
    )

  if(plotFlowNorm) lines(subAnnualResults$DecYear, fnFlux, col=col.pred, lwd=lwd)
    
}