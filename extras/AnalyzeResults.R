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
