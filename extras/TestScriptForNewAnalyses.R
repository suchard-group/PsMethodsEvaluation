library(LegendT2dmTestCases)
library(CohortMethod)

# Optional: specify where the temporary files (used by the Andromeda package) will be created:
options(andromedaTempFolder = "E:/Li_R/temp")

# Maximum number of cores to be used:
maxCores <- 6

# The folder where the study intermediate and result files will be written:
outputFolder <- "E:/Li_R/t2dmPsTrial2"

# Details for connecting to the server:
dbms <- "redshift"
user <- Sys.getenv("username")
pw <- Sys.getenv("password")
server <- "ohda-prod-1.cldcoxyrkflo.us-east-1.redshift.amazonaws.com/truven_mdcr"
port <- 5439

connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = dbms,
                                                                server = server,
                                                                user = user,
                                                                password = pw,
                                                                port = port)
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


### Small-scale PS model test

cs <- createCovariateSettings(useDemographicsAgeGroup = TRUE,
                              useDemographicsGender = TRUE,
                              useDemographicsRace = TRUE,
                              useDemographicsEthnicity = TRUE,
                              useDemographicsIndexYear = TRUE,
                              useDemographicsIndexMonth = TRUE,
                              useConditionOccurrenceLongTerm = TRUE,
                              useConditionOccurrenceShortTerm = TRUE,
                              useConditionOccurrencePrimaryInpatientMediumTerm = TRUE,
                              useConditionEraLongTerm = TRUE,
                              useConditionEraAnyTimePrior = TRUE,
                              useConditionEraOverlapping = TRUE,
                              useConditionGroupEraLongTerm = TRUE,
                              useConditionGroupEraShortTerm = TRUE,
                              useDrugExposureLongTerm = TRUE,
                              useDrugExposureShortTerm = TRUE,
                              useDrugEraLongTerm = TRUE,
                              useDrugEraShortTerm = TRUE,
                              useDrugEraOverlapping = TRUE,
                              useDrugEraAnyTimePrior = TRUE,
                              useDrugGroupEraLongTerm = TRUE,
                              useDrugGroupEraShortTerm = TRUE,
                              useProcedureOccurrenceLongTerm = TRUE,
                              useProcedureOccurrenceShortTerm = TRUE,
                              useObservationLongTerm = TRUE,
                              useObservationShortTerm = TRUE,
                              useMeasurementLongTerm = TRUE,
                              useMeasurementShortTerm = TRUE,
                              useDistinctMeasurementCountLongTerm = TRUE,
                              useVisitConceptCountLongTerm = TRUE,
                              useDcsi =  TRUE,
                              useChads2 = TRUE,
                              useCharlsonIndex = TRUE,
                              useChads2Vasc = TRUE,
                              excludedCovariateConceptIds = c(44631830, 44643066, 44643067, 44580621, 44552268, 44667448, 40228160, 40163507, 40163555, 1919876, 21105415, 21046557, 21046553, 
                                                              21124835, 21154566, 21070584, 21070583, 21174169, 21154557, 21046546, 21046548, 21046550, 21095531, 21046558, 21124829, 21046543, 
                                                              21154558, 40093132, 40093134, 40093131, 44663115, 44647884, 44578361, 44662478, 44637417, 44626965, 44622848, 44616175, 44622752, 44559160, 
                                                              44614948, 44579352, 44679336, 40228165, 40163523, 40163533, 40163517, 40228153, 40163520, 40163510, 40163518, 40163524, 40163550, 40163551, 
                                                              40163552, 40163514, 40163516, 21174175, 21174174, 21174173, 21146301, 21139109, 21028548, 21026878, 21174167, 21174165, 21026881, 21174163, 
                                                              21174168, 21174170, 21026875, 21026871, 21026880, 21026873, 21026874, 21139110, 21174172, 21174166, 21154559, 21118373, 21139108, 21174171, 
                                                              44579230, 44626589, 44612008, 44556574, 44545243, 44611547, 44562589, 44616988, 44617776, 44569040, 44611706, 44611705, 44563518, 44644475, 
                                                              35606207, 40163539, 40163545, 40163536, 35606210, 40163542, 40163541, 1310149, 44549319, 44549318, 44644567, 44650425, 44677342, 44653078, 
                                                              44625675, 44678256, 44560746, 44632290, 44548797, 44611597, 44607132, 44562846, 44556166, 44632766, 44609374, 44674154, 44589399, 44599599, 
                                                              44604248, 40163567, 40228161, 40163546, 40163570, 40163522, 40163569, 1946562, 1911780, 1934457, 1946563, 1895951, 1946564, 1946566, 21105426, 
                                                              21144643, 21124844, 21105427, 21066141, 21095537, 21066136, 21148980, 21144636, 21148981, 21105416, 21066137, 21089998, 21066129, 21105417, 
                                                              21089997, 21144647, 21156284, 21105421, 21105424, 21105422, 21154568, 21144639, 21039906, 21105419, 21124839, 21066132, 21154564, 21154571, 
                                                              21144640, 21095539, 21105425, 21154570, 21095533, 21031114, 21095538, 21154569, 21105429, 21105418, 21095536, 21144637, 21154576, 21105420, 
                                                              21124840, 21066130, 21144645, 21144638, 21144635, 21144646, 21095534, 21095532, 21095543, 44665051, 44547738, 44578601, 44587502, 44657905, 
                                                              44548604, 44556575, 44667136, 44570203, 44595885, 44587179, 44602298, 44670738, 44557985, 44643120, 44571574, 44559390, 40228164, 40228152, 
                                                              40121984, 44667174, 44551746, 44547357, 44583471, 40163540, 40163556, 1911779, 1946565, 21095541, 21124838, 21066140, 21144648, 21095542, 
                                                              21095540, 21048167, 40093133, 44645391, 44605024, 40228154, 44586763, 1854125, 21154555, 21146300, 21139111, 21046555, 21098809, 21046549, 
                                                              21046547, 21154556, 40093130, 44657834, 44561018, 44560351, 44657833, 44607893, 44630908, 44604212, 44658031, 44621649, 44642416, 44645771,
                                                              44635583, 44622849, 44550692, 44617269, 44581120, 44563271, 44672367, 40163529, 40163519, 40163526, 40163525, 40228163, 40163544, 40163515, 
                                                              40228159, 1928668, 1954627, 1939441, 21134746, 21036676, 21115236, 21115241, 21134748, 21026882, 21036677, 21115242, 21115237, 21166047, 
                                                              21028545, 21028546, 21036673, 21115235, 21080282, 21115228, 21134747, 21115238, 21036678, 21134745, 21041017, 21036671, 21028547, 21115243, 
                                                              21026877, 21115234, 21026872, 21028549, 21115239, 21026879, 21026876, 21036675, 21115240, 21177359, 21174164, 35606208, 40163543, 40163527, 
                                                              40163538, 40163537, 1869490, 1869486, 1869492, 21164383, 21056316, 21134735, 21164395, 21056299, 21085794, 21050809, 21129251, 21158904, 21164394, 
                                                              21050808, 21038354, 21038355, 21136441, 21085792, 21085789, 21076070, 21134737, 21076071, 21056302, 21056301, 21085786, 21076067, 21056297, 21076065, 
                                                              21050807, 21056309, 21056306, 21136442, 21119453, 21134739, 21056300, 21085788, 21076069, 21076066, 21164388, 21056310, 21107063, 21056307, 21164393, 
                                                              21119454, 21134736, 21056311, 21164389, 21129249, 21166045, 21056315, 21164392, 21056314, 21164391, 21164390, 21056312, 21107064, 21116823, 21115226, 
                                                              21116820, 40163561, 40163562, 40163535, 40163547, 40163548, 40163563, 40163558, 40163557, 40163564, 35606209, 40163528, 21134734, 21095547, 21076074, 
                                                              21085793, 21175784, 21175783, 21167612, 21109717, 21129248, 21031115, 21085784, 21085781, 21085782, 21056295, 21095545, 21085785, 21129250, 21129247, 
                                                              21085783, 21056296, 21085787, 21095546, 21056298, 21085790, 21134738, 21109716, 21095544, 21031116, 21164387, 21076075, 21164385, 21085791, 21056304, 
                                                              21076068, 21119455, 21164384, 21119456, 21164386, 21056308, 21056303, 21076073, 21056305, 21076072, 44627226, 44665175, 44604598, 44631436, 44676840, 
                                                              44674155, 44601988, 44611173, 44546930, 44574108, 44656985, 44605858, 44610278, 44674600, 40163509, 40228162, 40163549, 40163512, 40163568, 40163566, 
                                                              40163554, 40163532, 40163521, 1884820, 1863015, 1884823, 1884822, 1854129, 1854128, 1919877, 1854127, 21105414, 21105413, 21154567, 21070582, 21124832, 
                                                              21154563, 21095535, 21124831, 21154565, 21046556, 21059492, 21046544, 21046545, 21154561, 21124837, 21154572, 21144644, 21124830, 21046554, 21154560, 
                                                              21124841, 21124833, 21124834, 21124842, 21066133, 21066135, 21154562, 21046551, 21046552, 21124836, 21066128, 21154573, 21154574, 21105423, 21124843, 
                                                              21066131, 40121983, 40163565, 1878227, 21036670, 21036672, 21116821, 21115231, 21036667, 21115230, 21134741, 21126572, 40163553, 40163559, 40228158,
                                                              40163531, 1869489, 1913367, 1878226, 1869493, 1869491, 1869485, 1878225, 21134742, 21116819, 21166046, 21107066, 21077698, 21107065, 21116822, 21036666, 
                                                              21116818, 21036668, 21077697, 21115229, 21056317, 21080281, 21126573, 21115232, 21134740, 21116824, 21115227, 21056313, 21036669, 21134743, 21115233, 
                                                              21036674, 21136443, 21134744, 21066143, 21144641, 44655361, 44622055, 21144642, 40163560, 44618390, 21066139, 21154575, 44603265, 40163511, 21105428, 
                                                              21066134, 40163508, 44647604, 44663782, 40163513, 44662517, 21056294, 44605424, 21066138, 21066142, 40163530, 40163534),
                              addDescendantsToExclude = TRUE
                              )

cs1 <- createCovariateSettings(useDemographicsAgeGroup = TRUE,
                               useDemographicsGender = TRUE,
                               useDemographicsRace = TRUE,
                               useDemographicsEthnicity = TRUE,
                               useDemographicsIndexYear = TRUE,
                               useDemographicsIndexMonth = TRUE,
                               useConditionOccurrenceLongTerm = TRUE,
                               useConditionOccurrenceShortTerm = TRUE,
                               useConditionOccurrencePrimaryInpatientMediumTerm = TRUE,
                               useConditionEraLongTerm = TRUE,
                               useConditionEraAnyTimePrior = TRUE,
                               useConditionEraOverlapping = TRUE,
                               useConditionGroupEraLongTerm = TRUE,
                               useConditionGroupEraShortTerm = TRUE,
                               useDrugExposureLongTerm = TRUE,
                               useDrugExposureShortTerm = TRUE,
                               useDrugEraLongTerm = TRUE,
                               useDrugEraShortTerm = TRUE,
                               useDrugEraOverlapping = TRUE,
                               useDrugEraAnyTimePrior = TRUE,
                               useDrugGroupEraLongTerm = TRUE,
                               useDrugGroupEraShortTerm = TRUE,
                               useProcedureOccurrenceLongTerm = TRUE,
                               useProcedureOccurrenceShortTerm = TRUE,
                               useObservationLongTerm = TRUE,
                               useObservationShortTerm = TRUE,
                               useMeasurementLongTerm = TRUE,
                               useMeasurementShortTerm = TRUE,
                               useDistinctMeasurementCountLongTerm = TRUE,
                               useVisitConceptCountLongTerm = TRUE,
                               useDcsi =  TRUE,
                               useChads2 = TRUE,
                               useCharlsonIndex = TRUE,
                               useChads2Vasc = TRUE,
                               includedCovariateIds = c(0:20*1000 + 3, #Age groups
                                                        8532001, # Female,
                                                        2000:2020*1000 + 6, # Index year
                                                        201826210, # T2DM
                                                        317576210, # CAD
                                                        4329847210, # MI
                                                        317009210, # Asthma
                                                        316139210, # Heart failure
                                                        46271022210, # Chronic kidney disease
                                                        313217210, # Atrial fibrillation,
                                                        1901, # Charlson index - Romano adaptation
                                                        21600985410, # Platelet aggregation inhibitors excl. heparin
                                                        1310149410, # Warfarin
                                                        21602722410, # Corticosteroids for systemic use
                                                        1331270410, # Dipyridamole
                                                        21603933410, # NSAIDS
                                                        21600095410, # PPIs
                                                        21601855410, # Statins
                                                        21602514410, # Estrogens
                                                        21602537410, # Progestogens
                                                        21600712410, # Anti-glycemic agent
                                                        4245997802, # BMI
                                                        255573210, # COPD
                                                        4212540210, # Liver disease
                                                        4159131210, # Dyslipidemia
                                                        4281749210, # Valvular heart disease
                                                        4239381210, # Drug abuse
                                                        443392210, # Cancer
                                                        439727210) # HIV infection
                               )
                               

cmData <- getDbCohortMethodData(
  connectionDetails = connectionDetails,
  cdmDatabaseSchema = cdmDatabaseSchema,
  targetId = 201100000,
  comparatorId = 101100000,
  outcomeIds = 541,
  exposureDatabaseSchema = cohortDatabaseSchema,
  exposureTable = cohortTable,
  outcomeDatabaseSchema = cohortDatabaseSchema,
  outcomeTable = cohortTable,
  covariateSettings = cs1
)
