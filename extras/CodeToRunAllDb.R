#CCAE
connectionDetailsCCAE <- DatabaseConnector::createConnectionDetails(
  dbms = "redshift",
  server = "ohda-prod-1.cldcoxyrkflo.us-east-1.redshift.amazonaws.com/truven_ccae",
  port = 5439,
  user = keyring::key_get("user", "kli69"),
  password = keyring::key_get("password", "kli69"),
  extraSettings = "ssl=true&sslfactory=com.amazon.redshift.ssl.NonValidatingFactory")
cdmDatabaseSchemaCCAE <- "cdm_truven_ccae_v2887"
databaseIdCCAE <- "truven_ccae"
databaseNameCCAE <- "IBM MarketScan Commercial Claims and Encounters (CCAE)"
databaseDescriptionCCAE <- "Adjudicated health insurance claims (e.g. inpatient, outpatient, and outpatient pharmacy)  from large employers and health plans who provide private healthcare coverage to employees, their spouses and dependents."
outputFolderCCAE <- "E:/Li_R/t2dm_ccae"

#MDCD
connectionDetailsMDCD <- DatabaseConnector::createConnectionDetails(
  dbms = "redshift",
  server = "ohda-prod-1.cldcoxyrkflo.us-east-1.redshift.amazonaws.com/truven_mdcd",
  port = 5439,
  user = keyring::key_get("user", "kli69"),
  password = keyring::key_get("password", "kli69"),
  extraSettings = "ssl=true&sslfactory=com.amazon.redshift.ssl.NonValidatingFactory")
cdmDatabaseSchemaMDCD <- "cdm_truven_mdcd_v2757"
databaseIdMDCD <- "truven_mdcd"
databaseNameMDCD <- "IBM MarketScan Multi-State Medicaid Database (MDCD)"
databaseDescriptionMDCD <- "Adjudicated health insurance claims for Medicaid enrollees from multiple states and includes hospital discharge diagnoses, outpatient diagnoses and procedures, and outpatient pharmacy claims."
outputFolderMDCD <- "E:/Li_R/t2dm_mdcd"

#Optum EHR
connectionDetailsOptumEhr <- DatabaseConnector::createConnectionDetails(
  dbms = "redshift",
  server = "ohda-prod-1.cldcoxyrkflo.us-east-1.redshift.amazonaws.com/optum_ehr",
  port = 5439,
  user = keyring::key_get("user", "kli69"),
  password = keyring::key_get("password", "kli69"),
  extraSettings = "ssl=true&sslfactory=com.amazon.redshift.ssl.NonValidatingFactory")
cdmDatabaseSchemaOptumEhr <- "cdm_optum_ehr_v2779"
databaseIdOptumEhr <- "optum_ehr"
databaseNameOptumEhr <- " Optum Electronic Health Records (OptumEHR)"
databaseDescriptionOptumEhr <- "Clinical information, prescriptions, lab results, vital signs, body measurements, diagnoses and procedures derived from clinical notes using natural language processing."
outputFolderOptumEhr <- "E:/Li_R/t2dm_optumehr"



# Add a sharebale name for the database containing the OMOP CDM data
cdmDatabaseName <- 't2dmPs'
# Add a database with read/write access as this is where the cohorts will be generated
cohortDatabaseSchema <- 'scratch_kli69'
tempEmulationSchema <- NULL
# table name where the cohorts will be generated
cohortTable <- 't2dmPs'

# For some database platforms (e.g. Oracle): define a schema that can be used to emulate temp tables:
options(sqlRenderTempEmulationSchema = NULL)


execute(connectionDetails = connectionDetailsCCAE,
        cdmDatabaseSchema = cdmDatabaseSchemaCCAE,
        cohortDatabaseSchema = cohortDatabaseSchema,
        cohortTable = cohortTable,
        outputFolder = outputFolderCCAE,
        databaseId = databaseIdCCAE,
        databaseName = databaseNameCCAE,
        databaseDescription = databaseDescriptionCCAE,
        createCohorts = TRUE,
        synthesizePositiveControls = FALSE,
        runAnalyses = FALSE,
        packageResults = FALSE,
        maxCores = maxCores)

execute(connectionDetails = connectionDetailsOptumEhr,
        cdmDatabaseSchema = cdmDatabaseSchemaOptumEhr,
        cohortDatabaseSchema = cohortDatabaseSchema,
        cohortTable = cohortTable,
        outputFolder = outputFolderOptumEhr,
        databaseId = databaseIdOptumEhr,
        databaseName = databaseNameOptumEhr,
        databaseDescription = databaseDescriptionOptumEhr,
        createCohorts = TRUE,
        synthesizePositiveControls = FALSE,
        runAnalyses = FALSE,
        packageResults = FALSE,
        maxCores = maxCores)

execute(connectionDetails = connectionDetailsMDCD,
        cdmDatabaseSchema = cdmDatabaseSchemaMDCD,
        cohortDatabaseSchema = cohortDatabaseSchema,
        cohortTable = cohortTable,
        outputFolder = outputFolderMDCD,
        databaseId = databaseIdMDCD,
        databaseName = databaseNameMDCD,
        databaseDescription = databaseDescriptionMDCD,
        createCohorts = TRUE,
        synthesizePositiveControls = FALSE,
        runAnalyses = FALSE,
        packageResults = FALSE,
        maxCores = maxCores)

counts_mdcr <- read.csv("E:/Li_R/t2dmPsTrial2/CohortCounts.csv") %>% filter(cohortDefinitionId %in% c(101100000, 201100000, 301100000, 401100000)) %>%
  rename("mdcr" = "cohortCount")
counts_ccae <- read.csv(file.path(outputFolderCCAE, "CohortCounts.csv")) %>% filter(cohortDefinitionId %in% c(101100000, 201100000, 301100000, 401100000)) %>%
  rename("ccae" = "cohortCount")
counts_mdcd <- read.csv(file.path(outputFolderMDCD, "CohortCounts.csv")) %>% filter(cohortDefinitionId %in% c(101100000, 201100000, 301100000, 401100000)) %>%
  rename("mdcd" = "cohortCount")
counts_optumehr <- read.csv(file.path(outputFolderOptumEhr, "CohortCounts.csv")) %>% filter(cohortDefinitionId %in% c(101100000, 201100000, 301100000, 401100000)) %>%
  rename("optum_ehr" = "cohortCount")

counts_total <- left_join(counts_mdcr, counts_ccae, by = c("cohortDefinitionId", "cohortName")) %>%
  left_join(counts_mdcd, by = c("cohortDefinitionId", "cohortName")) %>%
  left_join(counts_optumehr, by = c("cohortDefinitionId", "cohortName")) %>%
  select(order(colnames(.))) %>%
  select(cohortName, cohortDefinitionId, ccae, mdcd, mdcr, optum_ehr)

saveRDS(counts_total, "./documents/figures/cohortCounts.rds")
