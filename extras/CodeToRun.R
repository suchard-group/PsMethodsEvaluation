library(LegendT2dmTestCases)

# Optional: specify where the temporary files (used by the Andromeda package) will be created:
options(andromedaTempFolder = "E:/Li_R/temp")
Sys.setenv(DATABASECONNECTOR_JAR_FOLDER = "E:/Li_R/Drivers")

# Maximum number of cores to be used:
maxCores <- 6

# The folder where the study intermediate and result files will be written:
outputFolder <- "E:/Li_R/t2dmPsTrial3"

# Details for connecting to the server:
server <- "mdcr_server_name"
connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = "redshift",
                                                                server = keyring::key_get("mdcr_server"),
                                                                user = keyring::key_get("user", "kli69"),
                                                                password = keyring::key_get("password", "kli69"),
                                                                port = 5439)

# Add the database containing the OMOP CDM data
cdmDatabaseSchema <- "cdm_truven_mdcr_v2755"
# Add a sharebale name for the database containing the OMOP CDM data
cdmDatabaseName <- 't2dmPs'
# Add a database with read/write access as this is where the cohorts will be generated
cohortDatabaseSchema <- 'scratch_kli69'

tempEmulationSchema <- NULL

# table name where the cohorts will be generated
cohortTable <- 't2dmPs'

# Some meta-information that will be used by the export function:
databaseId <- "IBM_MDCR"
databaseName <- "IBM MarketScan® Medicare Supplemental and Coordination of Benefits Database"
databaseDescription <- "IBM MarketScan® Medicare Supplemental and Coordination of Benefits Database (MDCR) represents health services of retirees in the United States with primary or Medicare supplemental coverage through privately insured fee-for-service, point-of-service, or capitated health plans.  These data include adjudicated health insurance claims (e.g. inpatient, outpatient, and outpatient pharmacy). Additionally, it captures laboratory tests for a subset of the covered lives."

# For some database platforms (e.g. Oracle): define a schema that can be used to emulate temp tables:
options(sqlRenderTempEmulationSchema = NULL)

# createAnalysesDetails(outputFolder = "E:/Li_R/LegendT2dmTestCases/inst/settings")

# # Write negative controls list
# tcs <- read.csv("./inst/settings/TcosOfInterest.csv") %>%
#   select(unique(c("targetId", "comparatorId")))
# 
# ncs <- read.csv("./inst/settings/NegativeControlsFinal.csv") %>%
#   select(origin, outcomeId, outcomeName, cohortId)
# 
# expanded_table <- do.call(rbind, lapply(1:nrow(tcs), function(i) {
#   cbind(ncs, tcs[i, ])
# }))
# 
# write.csv(expanded_table, file = "./inst/settings/NegativeControls.csv",
#           row.names = F, quote = F)

outputFolder <- "E:/Li_R/t2dmPsTrial2"
execute(connectionDetails = connectionDetails,
        cdmDatabaseSchema = cdmDatabaseSchema,
        cohortDatabaseSchema = cohortDatabaseSchema,
        cohortTable = cohortTable,
        outputFolder = outputFolder,
        databaseId = databaseId,
        databaseName = databaseName,
        databaseDescription = databaseDescription,
        createCohorts = FALSE,
        synthesizePositiveControls = FALSE,
        runAnalyses = FALSE,
        packageResults = TRUE,
        maxCores = maxCores)


resultsZipFile <- file.path(outputFolder, "export", paste0("Results_", databaseId, ".zip"))
dataFolder <- file.path(outputFolder, "shinyData")
# You can inspect the results if you want:
LegendT2dm::prepareForEvidenceExplorer(resultsZipFile = resultsZipFile, dataFolder = dataFolder)
LegendT2dmEvidenceExplorer::launchEvidenceExplorer(dataFolder = dataFolder, blind = FALSE, launch.browser = FALSE)

# # Grab estimates to compare with main LEGEND-T2DM
# library(dplyr)
# 
# analysisSummary <- read.csv(file.path(outputFolder, "analysisSummary.csv"))
# rbind(
#   analysisSummary %>% filter(outcomeId == 1) %>% 
#     select(analysisId, rr) %>% arrange(analysisId),
#   analysisSummary %>% filter(outcomeId == 6, analysisId %in% c(1,2,3)) %>% 
#     mutate(analysisId = analysisId + 6) %>% select(analysisId, rr) %>% arrange(analysisId)
# )




# Insert results into database 
personal_server <- "/Users/kellyli/Documents/sqlite-tools-osx-x64-3490100/ohdsitest.db"
resultsConnectionDetails <- createConnectionDetails(dbms = "sqlite",
                                                    server = personal_server)
resultsFolder <- file.path(outputFolder, "export")

uploadResultsToDatabase(connectionDetails = resultsConnectionDetails,
                        schema = "main",
                        resultsFolder = resultsFolder)
