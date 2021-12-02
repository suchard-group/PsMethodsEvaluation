library(LegendT2dmTestCases)

# Optional: specify where the temporary files (used by the Andromeda package) will be created:
options(andromedaTempFolder = "D:/Users/msuchard/Documents/LegendT2dmTestCasesOutputShort")

# Maximum number of cores to be used:
maxCores <- 1

# The folder where the study intermediate and result files will be written:
outputFolder <- "D:/Users/msuchard/Documents/LegendT2dmTestCasesOutputShort"
pathToDriver <- "D:/Users/msuchard/Documents/Drivers"

# Details for connecting to the server from Legend T2dm:
oracleTempSchema <- NULL
cdmDatabaseSchema <- "cdm_truven_mdcr_v1838" # MAS: I just updated to most recent
#serverSuffix <- "truven_mdcr"
cohortDatabaseSchema <- "scratch_msuchard"
cohortTable <- "legendt2dm_testcases"

databaseId<- "MDCR"
databaseName <- "IBM Health MarketScan Medicare Supplemental and Coordination of Benefits Database"
databaseDescription <- "IBM Health MarketScan® Medicare Supplemental and Coordination of Benefits Database (MDCR) represents health services of retirees in the United States with primary or Medicare supplemental coverage through privately insured fee-for-service, point-of-service, or capitated health plans. These data include adjudicated health insurance claims (e.g. inpatient, outpatient, and outpatient pharmacy). Additionally, it captures laboratory tests for a subset of the covered lives."

connectionDetails <- DatabaseConnector::createConnectionDetails(
        dbms = "redshift",
        server = paste0(keyring::key_get("redshiftServer"), "/", "truven_mdcr"),
        port = 5439,
        user = keyring::key_get("redshiftUser"),
        password = keyring::key_get("redshiftPassword"),
        extraSettings = "ssl=true&sslfactory=com.amazon.redshift.ssl.NonValidatingFactory")

execute(connectionDetails = connectionDetails,
        cdmDatabaseSchema = cdmDatabaseSchema,
        cohortDatabaseSchema = cohortDatabaseSchema,
        cohortTable = cohortTable,
        oracleTempSchema = oracleTempSchema,
        outputFolder = outputFolder,
        databaseId = databaseId,
        databaseName = databaseName,
        databaseDescription = databaseDescription,
        createCohorts = TRUE,
        synthesizePositiveControls = FALSE,
        runAnalyses = TRUE,
        packageResults = TRUE,
        maxCores = maxCores)

resultsZipFile <- file.path(outputFolder, "export", paste0("Results_", databaseId, ".zip"))
dataFolder <- file.path(outputFolder, "shinyData")

# You can inspect the results if you want:
prepareForEvidenceExplorer(resultsZipFile = resultsZipFile, dataFolder = dataFolder)
launchEvidenceExplorer(dataFolder = dataFolder, blind = TRUE, launch.browser = FALSE)

# Upload the results to the OHDSI SFTP server:
privateKeyFileName <- ""
userName <- ""
uploadResults(outputFolder, privateKeyFileName, userName)