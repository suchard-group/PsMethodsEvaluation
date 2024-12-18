library(MethodEvaluation)
library(formattable)
library(kableExtra)

estimates <- readRDS(file.path(outputFolder, "cmOutput", "resultsSummary.rds"))
controlSummary <- read.csv(file.path(outputFolder, "allControls.csv"))

cmList <- readRDS(file.path(outputFolder, "cmOutput", "cmAnalysisList.rds"))

metricSet <- merge(estimates, 
                   controlSummary[, c("targetId", 
                                      "outcomeId", 
                                      "targetEffectSize", 
                                      "trueEffectSize", 
                                      "trueEffectSizeFirstExposure")])
metricSet <- split(metricSet, metricSet$analysisId)




analysisSumm <- read.csv(file.path(outputFolder, "analysisSummary.csv")) 
analysisRef <- analysisSumm %>% distinct(analysisId, analysisDescription)

getMetrics <- function(data){
  return(MethodEvaluation::computeMetrics(logRr = data$logRr,
                                          seLogRr = data$seLogRr,
                                          ci95Lb = data$ci95Lb,
                                          ci95Ub = data$ci95Ub,
                                          p = data$p,
                                          trueLogRr = log(data$trueEffectSize)))
}

getMetrics(metricSet[[1]])

metrics <- sapply(1:nrow(analysisRef), function(x)getMetrics(metricSet[[x]])) %>% t() %>% as_tibble()
metrics <- cbind(analysisRef, metrics)

metricSetCali <- merge(estimates, 
                       controlSummary[, c("targetId", 
                                          "outcomeId", 
                                          "targetEffectSize", 
                                          "trueEffectSize", 
                                          "trueEffectSizeFirstExposure")]) %>%
  select(analysisId, calibratedLogRr, calibratedSeLogRr, calibratedCi95Lb, calibratedCi95Ub, calibratedP, trueEffectSizeFirstExposure, trueEffectSize) %>%
  rename(logRr = calibratedLogRr,
         seLogRr = calibratedSeLogRr,
         ci95Lb = calibratedCi95Lb,
         ci95Ub = calibratedCi95Ub,
         p = calibratedP)

metricSetCali <- split(metricSetCali, metricSetCali$analysisId)

metricsCali <- sapply(1:nrow(analysisRef), function(x)getMetrics(metricSetCali[[x]])) %>% t() %>% as_tibble()
metricsCali <- cbind(analysisRef, metricsCali)

metrics %>% 
  formattable(list(
    auc = color_bar("lightpink"),
    coverage = color_bar("lightpink"),
    meanP = color_bar("lightpink"),
    mse = color_bar("lightblue"),
    type1 =color_bar("lightblue"),
    type2 = color_bar("lightblue"),
    nonEstimable = color_bar("lightgreen")
  ),
  align = "l")

metricsCali %>% 
  formattable(list(
    auc = color_bar("lightpink"),
    coverage = color_bar("lightpink"),
    meanP = color_bar("lightpink"),
    mse = color_bar("lightblue"),
    type1 =color_bar("lightblue"),
    type2 = color_bar("lightblue"),
    nonEstimable = color_bar("lightgreen")
  ),
  align = "l")

saveRDS(metrics, file = "./documents/figures/metricsPreCali.rds")
saveRDS(metricsCali, file = "./documents/figures/metricsCali.rds")


plotScatter <- function(controlResults) {
  size <- 2
  labelY <- 0.7
  controlResults <- controlResults %>% filter(trueEffectSize == 1)
  d <- rbind(data.frame(yGroup = "Uncalibrated",
                        logRr = controlResults$logRr,
                        seLogRr = controlResults$seLogRr,
                        ci95Lb = controlResults$ci95Lb,
                        ci95Ub = controlResults$ci95Ub,
                        trueRr = controlResults$trueEffectSize),
             data.frame(yGroup = "Calibrated",
                        logRr = controlResults$calibratedLogRr,
                        seLogRr = controlResults$calibratedSeLogRr,
                        ci95Lb = controlResults$calibratedCi95Lb,
                        ci95Ub = controlResults$calibratedCi95Ub,
                        trueRr = controlResults$trueEffectSize))
  d <- d[!is.na(d$logRr), ]
  d <- d[!is.na(d$ci95Lb), ]
  d <- d[!is.na(d$ci95Ub), ]
  if (nrow(d) == 0) {
    return(NULL)
  }
  d$Group <- as.factor(d$trueRr)
  d$Significant <- d$ci95Lb > d$trueRr | d$ci95Ub < d$trueRr
  temp1 <- aggregate(Significant ~ Group + yGroup, data = d, length)
  temp2 <- aggregate(Significant ~ Group + yGroup, data = d, mean)
  temp1$nLabel <- paste0(formatC(temp1$Significant, big.mark = ","), " estimates")
  temp1$Significant <- NULL
  
  temp2$meanLabel <- paste0(formatC(100 * (1 - temp2$Significant), digits = 1, format = "f"),
                            "% of CIs include ",
                            temp2$Group)
  temp2$Significant <- NULL
  dd <- merge(temp1, temp2)
  dd$tes <- as.numeric(as.character(dd$Group))
  
  breaks <- c(0.1, 0.25, 0.5, 1, 2, 4, 6, 8, 10)
  theme <- ggplot2::element_text(colour = "#000000", size = 12)
  themeRA <- ggplot2::element_text(colour = "#000000", size = 12, hjust = 1)
  themeLA <- ggplot2::element_text(colour = "#000000", size = 12, hjust = 0)
  
  d$Group <- paste("True hazard ratio =", d$Group)
  dd$Group <- paste("True hazard ratio =", dd$Group)
  alpha <- 1 - min(0.95 * (nrow(d)/nrow(dd)/50000)^0.1, 0.95)
  plot <- ggplot2::ggplot(d, ggplot2::aes(x = logRr, y = seLogRr), environment = environment()) +
    ggplot2::geom_vline(xintercept = log(breaks), colour = "#AAAAAA", lty = 1, size = 0.5) +
    ggplot2::geom_abline(ggplot2::aes(intercept = (-log(tes))/qnorm(0.025), slope = 1/qnorm(0.025)),
                         colour = rgb(0.8, 0, 0),
                         linetype = "dashed",
                         size = 1,
                         alpha = 0.5,
                         data = dd) +
    ggplot2::geom_abline(ggplot2::aes(intercept = (-log(tes))/qnorm(0.975), slope = 1/qnorm(0.975)),
                         colour = rgb(0.8, 0, 0),
                         linetype = "dashed",
                         size = 1,
                         alpha = 0.5,
                         data = dd) +
    ggplot2::geom_point(size = size,
                        color = rgb(0, 0, 0, alpha = 0.05),
                        alpha = alpha,
                        shape = 16) +
    ggplot2::geom_hline(yintercept = 0) +
    ggplot2::geom_label(x = log(0.15),
                        y = 0.9,
                        alpha = 1,
                        hjust = "left",
                        ggplot2::aes(label = nLabel),
                        size = 5,
                        data = dd) +
    ggplot2::geom_label(x = log(0.15),
                        y = labelY,
                        alpha = 1,
                        hjust = "left",
                        ggplot2::aes(label = meanLabel),
                        size = 5,
                        data = dd) +
    ggplot2::scale_x_continuous("Hazard ratio",
                                limits = log(c(0.1, 10)),
                                breaks = log(breaks),
                                labels = breaks) +
    ggplot2::scale_y_continuous("Standard Error", limits = c(0, 1)) +
    ggplot2::facet_grid(yGroup ~ Group) +
    ggplot2::theme(panel.grid.minor = ggplot2::element_blank(),
                   panel.background = ggplot2::element_blank(),
                   panel.grid.major = ggplot2::element_blank(),
                   axis.ticks = ggplot2::element_blank(),
                   axis.text.y = themeRA,
                   axis.text.x = theme,
                   axis.title = theme,
                   legend.key = ggplot2::element_blank(),
                   strip.text.x = theme,
                   strip.text.y = theme,
                   strip.background = ggplot2::element_blank(),
                   legend.position = "none")
  
  return(plot)
}

for(i in 1:nrow(analysisRef)){
  plot <- plotScatter(metricSet[[i]]) +
    ggtitle(paste0(analysisRef$analysisDescription[i]))
  #ggsave(paste0("./documents/figures/caliScatterPlots/", "hr1_", "a", analysisRef$analysisId[i], ".png"))
  saveRDS(plot, 
          paste0("./documents/figures/caliScatterPlots/", "hr1_", "a", analysisRef$analysisId[i], ".rds"))
}

plots <- list()
for(i in 1:nrow(analysisRef)){
  plots[[i]] <- readRDS( paste0("./documents/figures/caliScatterPlots/", "hr1_", "a", analysisRef$analysisId[i], ".rds"))
}

remove_titles <- theme(
  axis.text.y = element_blank(),
  axis.ticks.y = element_blank(),
  axis.title.y = element_blank(),
  axis.title.x = element_blank(),
  axis.text.x = element_blank(),
  strip.text.x = element_blank(),
  strip.text.y = element_blank()
)

for(i in 1:nrow(analysisRef)){
  plots[[i]] <- plots[[i]] + remove_titles
}
ggarrange(plotlist = plots,
          common.legend = TRUE)
