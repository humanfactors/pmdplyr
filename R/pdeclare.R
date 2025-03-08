#' pdeclare
#'
#' WARNING: FOR NOW, BE AWARE THAT AFTER USING PDECLARE, MOST FUNCTIONS WILL NOT PRESERVE THE ATTRIBUTES.
#'
#' This function declares a tibble or data frame as a panel by adding three attributes to it:
#'
#' \itemize{
#'   \item \code{.i}, a character or character vector indicating the variables that constitute the individual-level panel identifier
#'   \item \code{.t}, a character vector indicating the time variable
#'   \item \code{.d}, a number indicating the gap
#' }
#'
#' Note that pdeclare does not require that \code{.i} and \code{.t} uniquely identify the observations in your data, but it will give a warning message (a maximum of once per session) if they do not.
#'
#' @param .df Data frame or tibble to declare as a panel.
#' @param .i Character or character vector with the variable names that identify the individual cases. If this is omitted, \code{pdeclare} will assume the data set is a single time series.
#' @param .t Character variable with the single variable name indicating the time. \code{pmdplyr} accepts two kinds of time variables: numeric variables where a fixed distance \code{.d} will take you from one observation to the next, or, if \code{.d=0}, any standard variable type with an order. Consider using the \code{time_variable()} function to create the necessary variable if your data uses a \code{Date} variable for time.
#' @param .d Number indicating the gap in \code{t} between one period and the next. For example, if \code{.t} indicates a single day but data is collected once a week, you might set \code{.d=7}. To ignore gap length and assume that "one period ago" is always the most recent prior observation in the data, set \code{.d=0}. By default, \code{.d=1}.
#' @param .uniqcheck Logical parameter. Set to TRUE to perform a check of whether \code{.i} and \code{.t} uniquely identify observations, and present a message if not. By default this is set to FALSE and the warning message occurs only once per session.
#' @name pdeclare
#'
#' @examples
#' library(magrittr)
#' data(SPrail)
#' #I set .d=0 here to indicate that I don't care how large the gap between one period and the next is
#' #If I want to use 'insert_date' for t,
#' #I need to transform it into an integer first; see time_variable()
#' SP <- pdeclare(SPrail,.i=c('origin','destination'),.t='insert_date',.d=0)
#' is_pdeclare(SP)
#' attr(SP,'.i')
#' attr(SP,'.t')
#' attr(SP,'.d')
#'
#' data(Scorecard)
#' #Here, year is an integer, so I can use it with .d = 1 to
#' #indicate that one period is a change of one unit in year
#' #Conveniently, .d = 1 is the default
#' Scorecard <- pdeclare(Scorecard,.i='unitid',.t='year')
#' is_pdeclare(Scorecard)
#'
NULL
#' @export


pdeclare <- function(.df,.i=NA,.t=NA,.d=1,.uniqcheck=FALSE) {

  #Check inputs
  check_panel_inputs(.df,.i,.t,.d,.uniqcheck)

  if (is.na(.d)) { .d <- 1 }

  #### Assign panel indicators
  attr(.df,'.i') <- .i
  attr(.df,'.t') <- .t
  attr(.df,'.d') <- .d

  return(.df)
}


check_panel_inputs <- function(.df,.i,.t,.d,.uniqcheck) {
  ####CHECK INPUTS
  if (sum(class(.df) %in% c('data.frame','tbl','tbl_df')) == 0) {
    stop('Requires data to be a data frame or tibble.')
  }
  if (sum(class(.df) == 'data.table') > 0) {
    warning('pmdplyr functions have not been tested with data.tables')
  }
  if (!(max(is.character(.i))) & min(is.na(.i)) == 0) {
    stop('.i must be a character variable or a character vector.')
  }
  if (!(is.character(.t)) & !is.na(.t)) {
    stop('.t must be a character variable.')
  }
  if (length(.t)>1) {
    stop('Only one time variable allowed.')
  }
  if (!(is.numeric(.d)) & !(is.na(.d))) {
    stop('.d must be numeric.')
  }
  if (min(is.na(.i)) == 0 & min(.i %in% names(.df)) == 0) {
    stop('Elements of .i must be variables present in the data.')
  }
  if (!is.na(.t) & min(.t %in% names(.df)) == 0) {
    stop('.t must be a variable present in the data.')
  }
  if (!is.na(.uniqcheck) & !is.logical(.uniqcheck)) {
    stop('.uniqcheck must be TRUE or FALSE.')
  }
  if (!is.na(.d) & !is.na(.t)) {
    if (.d > 0 & !is.numeric(.df[[.t]])) {
      stop('Unless .d = 0, indicating an ordinal time variable, .t must be numeric.')
    }
  }

  #### Warn about multiple obs per id/t, but only once per session
  if (getOption("pdeclare.warning4.0",TRUE) | .uniqcheck == TRUE) {
    # Check for uniqueness
    groupvec <- c(.i,.t)
    groupvec <- groupvec[!is.na(groupvec)]
    if (anyDuplicated(.df[,groupvec]) > 0) {
      message('Note that the selected .i and .t do not uniquely identify observations in the data.\nThis message will be displayed only once per session unless the uniqcheck option is set to TRUE.')
      options("pdeclare.warning4.0"=FALSE)
    }
  }
}

#' Function to check whether an object has been declared as panel data
#'
#' Checks whether a data set (\code{data.frame} or \code{tibble}) has been assigned panel identifiers in the \code{pmdplyr} format. If so, returns those identifiers.
#'
#' @param .df Data frame or tibble
#' @param .silent Set to TRUE to suppress output reporting what the panel identifiers are. Defaults to FALSE
#' @examples
#'
#' library(magrittr)
#' data(Scorecard)
#' Scorecard <- pdeclare(Scorecard,.i='unitid',.t='year')
#' is_pdeclare(Scorecard)
#'
#' @export

is_pdeclare <- function(.df,.silent=FALSE) {
  if (sum(class(.df) %in% c('data.frame','tbl','tbl_df')) == 0) {
    stop('Requires data to be a data frame or tibble.')
  }
  if (!is.logical(.silent)) {
    stop('silent must be TRUE or FALSE.')
  }

  i <- ifelse(is.null(attr(.df,'.i')),NA,paste0(attr(.df,'.i'),collapse=', '))
  t <- ifelse(is.null(attr(.df,'.t')),NA,attr(.df,'.t'))
  d <- ifelse(is.null(attr(.df,'.d')),NA,attr(.df,'.d'))

  if (is.na(i) & is.na(t) & is.na(d)) {
    return(FALSE)
  } else {
    if (.silent == FALSE) {
      message(paste('.i = ',i,'; .t = ',t,'; .d = ',d,'.',sep=''))
    }
    return(TRUE)
  }
}


declare_in_fcn_check <- function(.df,.i,.t,.d,.uniqcheck,.setpanel,.noneed=FALSE) {
  #Check inputs
  if (!is.na(.uniqcheck) & !is.logical(.uniqcheck)) {
    stop('uniqcheck must be TRUE or FALSE.')
  }
  if (!is.na(.setpanel) & !is.logical(.setpanel)) {
    stop('setpanel must be TRUE or FALSE.')
  }

  #Collect original panel settings, if any.
  #To be consistent with other input checking, make them NA not NULL if appropriate
  orig_i <- ifelse(is.null(attr(.df,'.i')),NA,attr(.df,'.i'))
  orig_t <- ifelse(is.null(attr(.df,'.t')),NA,attr(.df,'.t'))
  orig_d <- ifelse(is.null(attr(.df,'.d')),NA,attr(.df,'.d'))

  #If uniqcheck is TRUE but panel is not being reset, run through check_panel_inputs
  #just to check, using already-set panel info
  if (min(is.na(.i)) > 0 & is.na(.t) & is.na(.d) & .uniqcheck == TRUE) {
    check_panel_inputs(.df,.i=orig_i,.t=orig_t,.d=orig_d,.uniqcheck=TRUE)
  }

  #If nothing was declared, use the original values
  if (min(is.na(.i)) > 0 & is.na(.t) & is.na(.d)) {
    .i <- orig_i
    .t <- orig_t
    .d <- orig_d
  }

  #If everything is still missing and you need something, error
  if (min(is.na(.i)) > 0 & is.na(.t) & .noneed == FALSE) {
    stop('Attempt to use panel indicators i and/or t, but no i or t are declared in command or stored in data.')
  }


  return(list(
    orig_i=orig_i,
    orig_t=orig_t,
    orig_d=orig_d,
    i=.i,
    t=.t,
    d=.d
  ))
}
