createAnalysesDetails <- function(outputFolder,
                                  removeSubjectsWithPriorOutcome = TRUE,
                                  asUnitTest = FALSE) {
  
  getId <- function(id, removeSubjectsWithPriorOutcome) {
    ifelse(removeSubjectsWithPriorOutcome, id, id + 10)
  }
  
  getFile <- function(name, removeSubjectsWithPriorOutcome) {
    paste0(name, ifelse(removeSubjectsWithPriorOutcome, "", "Po"),
           "CmAnalysisList.json")
  }
  
  getDescription <- function(description, removeSubjectsWithPriorOutcome) {
    ifelse(removeSubjectsWithPriorOutcome,
           description,
           paste0(description, ", with prior outcome"))
  }
  
  # TODO This is still code-duplicated with CustomCmDataObjectBuilding.R lines 122 - 129
  # TODO getDbCmDataArgs is currently only used in the unit-tests; fix
  pathToCsv <- system.file("settings", "Indications.csv", package = "LegendT2dmTestCases")
  indications <- read.csv(pathToCsv)
  filterConceptIds <- as.character(indications$filterConceptIds[indications$indicationId == "class"])
  filterConceptIds <- as.numeric(strsplit(filterConceptIds, split = ";")[[1]])
  
  # create default covariateSettings
  defaultCovariateSettings =  FeatureExtraction::createDefaultCovariateSettings(
    excludedCovariateConceptIds = filterConceptIds,
    addDescendantsToExclude = TRUE)
  
  # add continuous age to covariateSettings
  defaultCovariateSettings$DemographicsAge = TRUE
  
  getDbCmDataArgs <- CohortMethod::createGetDbCohortMethodDataArgs(
    covariateSettings = defaultCovariateSettings
  )
  
  createStudyPopArgsOnTreatment <- CohortMethod::createCreateStudyPopulationArgs(
    restrictToCommonPeriod = TRUE,
    removeSubjectsWithPriorOutcome = removeSubjectsWithPriorOutcome,
    minDaysAtRisk = 0,
    riskWindowStart = 1,
    riskWindowEnd = 0,
    startAnchor = "cohort start",
    endAnchor = "cohort end")
  
  createStudyPopArgsItt <- CohortMethod::createCreateStudyPopulationArgs(
    restrictToCommonPeriod = TRUE,
    removeSubjectsWithPriorOutcome = removeSubjectsWithPriorOutcome,
    minDaysAtRisk = 0,
    riskWindowStart = 1,
    riskWindowEnd = 99999,
    startAnchor = "cohort start",
    endAnchor = "cohort end")
  
  createStudyPopArgsIttLagged <- CohortMethod::createCreateStudyPopulationArgs(
    restrictToCommonPeriod = TRUE,
    removeSubjectsWithPriorOutcome = removeSubjectsWithPriorOutcome,
    minDaysAtRisk = 0,
    riskWindowStart = 365,
    riskWindowEnd = 99999,
    startAnchor = "cohort start",
    endAnchor = "cohort end")
  
  createPsArgs <- CohortMethod::createCreatePsArgs(
    control = Cyclops::createControl(
      noiseLevel = "silent",
      cvType = "auto",
      tolerance = 2e-07,
      cvRepetitions = 1,
      startingVariance = 0.01,
      resetCoefficients = TRUE, # To maintain reproducibility
      # irrespective of multi-threading
      seed = 123),
    stopOnError = FALSE,
    maxCohortSizeForFitting = 1e+05,
    excludeCovariateIds = c(1002) # exclude continuous age from PS model
  )
  
  createPsArgsOverlap <- CohortMethod::createCreatePsArgs(
    control = Cyclops::createControl(
      noiseLevel = "silent",
      cvType = "auto",
      tolerance = 2e-07,
      cvRepetitions = 1,
      startingVariance = 0.01,
      resetCoefficients = TRUE, # To maintain reproducibility
      # irrespective of multi-threading
      seed = 123),
    stopOnError = FALSE,
    maxCohortSizeForFitting = 1e+05,
    excludeCovariateIds = c(1002),# exclude continuous age from PS model
    estimator = "ato" 
  )
  
  trimByPsArgs <- createTrimByPsArgs()
  
  matchOnPsArgsOneToOne <- CohortMethod::createMatchOnPsArgs(
    caliper = 0.2,
    caliperScale = "standardized logit",
    allowReverseMatch = FALSE,
    maxRatio = 1)
  
  matchOnPsArgsOneToFive <- CohortMethod::createMatchOnPsArgs(
    caliper = 0.2,
    caliperScale = "standardized logit",
    allowReverseMatch = FALSE,
    maxRatio = 5)
  
  matchOnPsArgsOneToTen <- CohortMethod::createMatchOnPsArgs(
    caliper = 0.2,
    caliperScale = "standardized logit",
    allowReverseMatch = FALSE,
    maxRatio = 10)
  
  matchOnPsArgsOneToHundred <- CohortMethod::createMatchOnPsArgs(
    caliper = 0.2,
    caliperScale = "standardized logit",
    allowReverseMatch = FALSE,
    maxRatio = 100)
  
  stratifyByPsArgsFive <- CohortMethod::createStratifyByPsArgs(
    numberOfStrata = 5,
    baseSelection = "all")
  stratifyByPsArgsTen <- CohortMethod::createStratifyByPsArgs(
    numberOfStrata = 10,
    baseSelection = "all")
  
  fitOutcomeModelArgs <- CohortMethod::createFitOutcomeModelArgs(
    modelType = "cox",
    stratified = FALSE,
    profileBounds = c(log(0.1), log(10)))
  
  fitOutcomeModelArgsStrat <- CohortMethod::createFitOutcomeModelArgs(
    modelType = "cox",
    stratified = TRUE,
    profileBounds = c(log(0.1), log(10)))
  
  cmAnalysis1 <- CohortMethod::createCmAnalysis(
    analysisId = getId(1, removeSubjectsWithPriorOutcome),
    description = getDescription("Unadjusted", removeSubjectsWithPriorOutcome),
    getDbCohortMethodDataArgs = getDbCmDataArgs,
    createStudyPopArgs = createStudyPopArgsItt,
    fitOutcomeModelArgs = fitOutcomeModelArgs)
  
  cmAnalysis2 <- CohortMethod::createCmAnalysis(
    analysisId = getId(2, removeSubjectsWithPriorOutcome),
    description = getDescription("PS 1:1, non stratified", removeSubjectsWithPriorOutcome),
    getDbCohortMethodDataArgs = getDbCmDataArgs,
    createStudyPopArgs = createStudyPopArgsItt,
    createPsArgs = createPsArgs,
    matchOnPsArgs = matchOnPsArgsOneToOne,
    fitOutcomeModelArgs = fitOutcomeModelArgs)
  
  cmAnalysis3 <- CohortMethod::createCmAnalysis(
    analysisId = getId(3, removeSubjectsWithPriorOutcome),
    description = getDescription("PS 1:1, stratified", removeSubjectsWithPriorOutcome),
    getDbCohortMethodDataArgs = getDbCmDataArgs,
    createStudyPopArgs = createStudyPopArgsItt,
    createPsArgs = createPsArgs,
    matchOnPsArgs = matchOnPsArgsOneToOne,
    fitOutcomeModelArgs = fitOutcomeModelArgsStrat)
  
  cmAnalysis4 <- CohortMethod::createCmAnalysis(
    analysisId = getId(4, removeSubjectsWithPriorOutcome),
    description = getDescription("PS 1:5, stratified", removeSubjectsWithPriorOutcome),
    getDbCohortMethodDataArgs = getDbCmDataArgs,
    createStudyPopArgs = createStudyPopArgsItt,
    createPsArgs = createPsArgs,
    matchOnPsArgs = matchOnPsArgsOneToFive,
    fitOutcomeModelArgs = fitOutcomeModelArgsStrat)
  
  cmAnalysis5 <- CohortMethod::createCmAnalysis(
    analysisId = getId(5, removeSubjectsWithPriorOutcome),
    description = getDescription("PS 1:10, stratified", removeSubjectsWithPriorOutcome),
    getDbCohortMethodDataArgs = getDbCmDataArgs,
    createStudyPopArgs = createStudyPopArgsItt,
    createPsArgs = createPsArgs,
    matchOnPsArgs = matchOnPsArgsOneToTen,
    fitOutcomeModelArgs = fitOutcomeModelArgsStrat)
  
  cmAnalysis6 <- CohortMethod::createCmAnalysis(
    analysisId = getId(6, removeSubjectsWithPriorOutcome),
    description = getDescription("PS stratification 5 groups, stratified", removeSubjectsWithPriorOutcome),
    getDbCohortMethodDataArgs = getDbCmDataArgs,
    createStudyPopArgs = createStudyPopArgsItt,
    createPsArgs = createPsArgs,
    stratifyByPsArgs = stratifyByPsArgsFive,
    fitOutcomeModelArgs = fitOutcomeModelArgsStrat)
  
  cmAnalysis7 <- CohortMethod::createCmAnalysis(
    analysisId = getId(7, removeSubjectsWithPriorOutcome),
    description = getDescription("PS stratification 10 groups, stratified", removeSubjectsWithPriorOutcome),
    getDbCohortMethodDataArgs = getDbCmDataArgs,
    createStudyPopArgs = createStudyPopArgsItt,
    createPsArgs = createPsArgs,
    stratifyByPsArgs = stratifyByPsArgsTen,
    fitOutcomeModelArgs = fitOutcomeModelArgsStrat)
  
  cmAnalysis8 <- CohortMethod::createCmAnalysis(
    analysisId = getId(8, removeSubjectsWithPriorOutcome),
    description = getDescription("PS matching VR, stratified", removeSubjectsWithPriorOutcome),
    getDbCohortMethodDataArgs = getDbCmDataArgs,
    createStudyPopArgs = createStudyPopArgsItt,
    createPsArgs = createPsArgs,
    matchOnPsArgs = matchOnPsArgsOneToHundred,
    fitOutcomeModelArgs = fitOutcomeModelArgsStrat)
  
  
  cmAnalysis9 <- CohortMethod::createCmAnalysis(
    analysisId = getId(9, removeSubjectsWithPriorOutcome),
    description = getDescription("IPTW, not stratified", removeSubjectsWithPriorOutcome),
    getDbCohortMethodDataArgs = getDbCmDataArgs,
    createStudyPopArgs = createStudyPopArgsItt,
    createPsArgs = createPsArgs,
    trimByPsArgs = trimByPsArgs,
    fitOutcomeModelArgs = fitOutcomeModelArgs)
  
  cmAnalysis10 <- CohortMethod::createCmAnalysis(
    analysisId = getId(10, removeSubjectsWithPriorOutcome),
    description = getDescription("IPTW, overlap weights, not stratified", removeSubjectsWithPriorOutcome),
    getDbCohortMethodDataArgs = getDbCmDataArgs,
    createStudyPopArgs = createStudyPopArgsItt,
    createPsArgs = createPsArgsOverlap,
    trimByPsArgs = trimByPsArgs,
    fitOutcomeModelArgs = fitOutcomeModelArgs)
  
  cmAnalysis11 <- CohortMethod::createCmAnalysis(
    analysisId = getId(11, removeSubjectsWithPriorOutcome),
    description = getDescription("PS 1:1, overlap weights, stratified", removeSubjectsWithPriorOutcome),
    getDbCohortMethodDataArgs = getDbCmDataArgs,
    createStudyPopArgs = createStudyPopArgsItt,
    createPsArgs = createPsArgsOverlap,
    matchOnPsArgs = matchOnPsArgsOneToOne,
    fitOutcomeModelArgs = fitOutcomeModelArgsStrat)
  
  cmAnalysis12 <- CohortMethod::createCmAnalysis(
    analysisId = getId(12, removeSubjectsWithPriorOutcome),
    description = getDescription("PS stratification 5 groups, overlap weights, stratified", removeSubjectsWithPriorOutcome),
    getDbCohortMethodDataArgs = getDbCmDataArgs,
    createStudyPopArgs = createStudyPopArgsItt,
    createPsArgs = createPsArgsOverlap,
    stratifyByPsArgs = stratifyByPsArgsFive,
    fitOutcomeModelArgs = fitOutcomeModelArgsStrat)
  
  cmAnalysis13 <- CohortMethod::createCmAnalysis(
    analysisId = getId(13, removeSubjectsWithPriorOutcome),
    description = getDescription("PS matching VR, overlap weights, stratified", removeSubjectsWithPriorOutcome),
    getDbCohortMethodDataArgs = getDbCmDataArgs,
    createStudyPopArgs = createStudyPopArgsItt,
    createPsArgs = createPsArgsOverlap,
    matchOnPsArgs = matchOnPsArgsOneToHundred,
    fitOutcomeModelArgs = fitOutcomeModelArgsStrat)
 
  if (asUnitTest) {
    CohortMethod::saveCmAnalysisList(list(cmAnalysis1, cmAnalysis2, cmAnalysis3,
                                          cmAnalysis4, cmAnalysis5, cmAnalysis6),
                                     file.path(outputFolder, ifelse(removeSubjectsWithPriorOutcome,
                                                                    "cmAnalysisList.json",
                                                                    "poCmAnalysisList.json")))
  } else {
    CohortMethod::saveCmAnalysisList(list(cmAnalysis1, cmAnalysis2, cmAnalysis3,
                                          cmAnalysis4, cmAnalysis5, cmAnalysis6,
                                          cmAnalysis7, cmAnalysis8, cmAnalysis9,
                                          cmAnalysis10, cmAnalysis11, cmAnalysis12,
                                          cmAnalysis13),
                                     file.path(outputFolder, "cmAnalysisList.json"))
  }
}
