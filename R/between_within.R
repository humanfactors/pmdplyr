#' Functions to perform standard panel-data calculations
#'
#' WARNING: FOR NOW, ALWAYS SPECIFY THE PANEL STRUCTURE EVERY TIME YOU CALL THIS FUNCTION. PDECLARE STATUS IS DROPPED BY MOST FUNCTIONS.
#'
#' This function performs the standard between and within transformations on panel data.
#'
#' @param .var Vector to be transformed
#' @param .df Data frame or tibble (usually the data frame or tibble that contains \code{.var}) which contains the panel structure variables either listed in \code{.i} and \code{.t}, or earlier declared with \code{pdeclare()}. If \code{tlag} is called inside of a \code{dplyr} verb, this can be omitted and the data will be picked up automatically.
#' @param .fcn The function to be passed to \code{dplyr::summarize()}. \code{x - .fcn(x)} within \code{.i} is the within tranformation. \code{.fcn(x)} within \code{.i} minus \code{.fcn} overall is the between transformation. This will almost always be the default \code{.fcn = function(x) mean(x,na.rm=TRUE)}.
#' @param .i Character or character vector with the variable names that identify the individual cases. Note that setting any one of \code{.i}, \code{.t}, or \code{.d} will override all three already applied to the data, and will return data that is \code{pdeclare()}d with all three, unless \code{.setpanel=FALSE}.
#' @param .t Character variable with the single variable name indicating the time. \code{pmdplyr} accepts two kinds of time variables: numeric variables where a fixed distance \code{.d} will take you from one observation to the next, or, if \code{.d=0}, any standard variable type with an order. Consider using the \code{time_variable()} function to create the necessary variable if your data uses a \code{Date} variable for time.
#' @param .d Number indicating the gap in \code{.t} between one period and the next. For example, if \code{.t} indicates a single day but data is collected once a week, you might set \code{.d=7}. To ignore gap length and assume that "one period ago" is always the most recent prior observation in the data, set \code{.d=0}. By default, \code{.d=1}.
#' @param .uniqcheck Logical parameter. Set to TRUE to always check whether \code{.i} and \code{.t} uniquely identify observations in the data. By default this is set to FALSE and the check is only performed once per session, and only if at least one of \code{.i}, \code{.t}, or \code{.d} is set.
#' @examples
#'
#' library(magrittr)
#' data(SPrail)
#' #Calculate within- and between-route variation in price and add it to the data
#' SPrail <- SPrail %>%
#'     dplyr::mutate(within_route = within(price,.i=c('origin','destination')),
#'     between_route = between(price,.i=c('origin','destination')))
#'
#' @name panel_calculations
NULL

#' @rdname panel_calculations
#' @export
within <- function(.var,.df=get(".", envir=parent.frame()),.fcn = function(x) mean(x,na.rm=TRUE),.i=NA,.t=NA,.d=NA,.uniqcheck=FALSE) {
  if (!is.vector(.var)) {
    stop('.var must be a vector.')
  }
  if (!is.character(.fcn) & !is.function(.fcn)) {
    stop('.fcn must be a function.')
  }

  #Check inputs and pull out panel info
  inp <- declare_in_fcn_check(.df,.i,.t,.d,.uniqcheck,.setpanel=FALSE)
  if (max(is.na(inp$i)) == 1) {
    stop('within() requires that .i be declared either in the function or by pdeclare().')
  }

  #We only need these
  .df <- .df %>% dplyr::select_at(inp$i)
  .df[,ncol(.df)+1] <- .var
  varname <- names(.df)[ncol(.df)]

  #Calculate within transformation
  .df <- .df %>%
    dplyr::group_by_at(inp$i) %>%
    dplyr::mutate_at(varname,.funs=function(x) x - .fcn(x)) %>%
    dplyr::ungroup()

  return(.df[[varname]])
}

#' @rdname panel_calculations
#' @export
between <- function(.var,.df=get(".", envir=parent.frame()),.fcn = function(x) mean(x,na.rm=TRUE),.i=NA,.t=NA,.d=NA,.uniqcheck=FALSE) {
  if (!is.vector(.var)) {
    stop('.var must be a vector.')
  }
  if (!is.character(.fcn) & !is.function(.fcn)) {
    stop('.fcn must be a function.')
  }

  #Check inputs and pull out panel info
  inp <- declare_in_fcn_check(.df,.i,.t,.d,.uniqcheck,.setpanel=FALSE)
  if (max(is.na(inp$i)) == 1) {
    stop('within() requires that .i be declared either in the function or by pdeclare().')
  }

  #We only need these
  .df <- .df %>% dplyr::select_at(inp$i)
  .df[,ncol(.df)+1] <- .var
  varname <- names(.df)[ncol(.df)]

  #Grand mean
  gm <- .fcn(.df[[varname]])

  #Calculate within transformation
  .df <- .df %>%
    dplyr::group_by_at(inp$i) %>%
    dplyr::mutate_at(varname,.funs=function(x) .fcn(x) - gm) %>%
    dplyr::ungroup()

  return(.df[[varname]])
}

