#' Plot Generic for Break Down Uncertainty Objects
#'
#' @param x an explanation created with \code{\link{break_down_uncertainty}}
#' @param ... other parameters.
#' @param show_boxplots logical if \code{TRUE} (default) boxplot will be plotted to show uncertanity of attributions
#' @param vcolors If \code{NA} (default), DrWhy colors are used.
#' @param title main title for the plot. Character vector of length 1. Default: "Break Down profile"
#' @param subtitle subtitles for various explanations. Lookup table or a function returning a character vector. Default: 'created for the \code{x$label} model'. See \code{\link[ggplot2]{labeller}} for more.
#' @param max_features maximal number of features to be included in the plot. By default it's \code{10}.
#'
#' @return a \code{ggplot2} object.
#' @importFrom stats reorder
#'
#' @references Explanatory Model Analysis. Explore, Explain and Examine Predictive Models. \url{https://pbiecek.github.io/ema}
#'
#' @examples
#' library("DALEX")
#' library("iBreakDown")
#'
#' set.seed(1313)
#' titanic_small <- titanic_imputed[sample(1:nrow(titanic),500), c(1,2,5,8)]
#'
#' model_titanic_glm <- glm(survived ~ gender + age + fare,
#'                          data = titanic_small, family = "binomial")
#'
#' explain_titanic_glm <- explain(model_titanic_glm,
#'                                data = titanic_small[, -4],
#'                                y = titanic_small[, 4])
#'
#' sh_rf <- shap(explain_titanic_glm, titanic_small[1, ])
#'
#' sh_rf
#' plot(sh_rf)
#'
#' \donttest{
#' ## Not run:
#' library("randomForest")
#' set.seed(1313)
#'
#' model <- randomForest(status ~ . , data = HR)
#' new_observation <- HR_test[1,]
#'
#' explainer_rf <- explain(model,
#'                         data = HR[1:1000,1:5],
#'                         y = HR$status[1:1000])
#'
#' bd_rf <- break_down_uncertainty(explainer_rf,
#'                            new_observation,
#'                            path = c(3,2,4,1,5),
#'                            show_boxplots = FALSE)
#' bd_rf
#' plot(bd_rf, max_features = 3)
#'
#' # example for regression - apartment prices
#' # here we do not have intreactions
#' model <- randomForest(m2.price ~ . , data = apartments)
#' explainer_rf <- explain(model,
#'                         data = apartments_test[1:1000,2:6],
#'                         y = apartments_test$m2.price[1:1000])
#'
#' bd_rf <- break_down_uncertainty(explainer_rf,
#'                                      apartments_test[1,],
#'                                      path = c("floor", "no.rooms", "district",
#'                                          "construction.year", "surface"))
#' bd_rf
#' plot(bd_rf)
#'
#' bd_rf <- shap(explainer_rf,
#'               apartments_test[1,])
#' bd_rf
#' plot(bd_rf)
#' plot(bd_rf, show_boxplots = FALSE)
#' }
#' @export
plot.break_down_uncertainty <- function(x, ...,
                  vcolors = DALEX::colors_breakdown_drwhy(),
                  show_boxplots = TRUE,
                  title = "Break Down profile",
                  subtitle = function(label) paste0("created for the ",label," model"),
                  max_features = 10) {

  # Check main title argument:
  if(!(is.character(title) && length(title == 1)))
    stop("title must be character vector of length 1")

  # Check subtitle argument:
  if(is.function(subtitle)){
    res <- subtitle(attr(x$label, "levels"))
    if(!(is.character(res) && length(res) == length(attr(x$label, "levels"))))
      stop("subtitle function not working properly")
  } else if(!(is.character(subtitle) &&
              length(setdiff(attr(x$label, "levels"), names(subtitle))) == 0))
    stop("subtitle, if vector, must be a named character containing x$label")
  facet_labeller <- labeller(label = subtitle)

  variable <- contribution <- NULL
  df <- as.data.frame(x)

  df$variable <- reorder(df$variable, df$contribution, function(x) mean(abs(x)))

  vnames <- tail(levels(df$variable), max_features)
  df <- df[df$variable %in% vnames, ]

  # base plot
  pl <- ggplot(df, aes(x = variable, y = contribution))
  if (any(df$B == 0)) {
    x_bars <- df[df$B == 0,]
    pl <- pl +
      geom_col(data = x_bars, aes(x = variable, y = contribution, fill = factor(sign(contribution)))) +
      scale_fill_manual(values = vcolors)
  }

  if (show_boxplots) {
    pl <- pl +
      geom_boxplot(coef = 100, fill = "#371ea3", color = "#371ea3", width = 0.25)
  }

  pl +
    labs(title = title) +
    facet_wrap(~label, ncol = 1, labeller = facet_labeller) +
    coord_flip() + theme_drwhy_vertical() +
    theme(legend.position = "none") + xlab("")
}

