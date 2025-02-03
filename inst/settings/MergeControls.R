library(tidyverse)
nc1 <- read.csv("./inst/settings/NegativeControlsT2dm.csv")
nc2 <- read.csv("./inst/settings/NegativeControlsGlp1Dili.csv")

names(nc2) <- c("cohortId", "outcomeName", "outcomeId")

same <- inner_join(nc1, nc2, by = "outcomeId") %>%
  mutate(outcomeName = outcomeName.y)

nc1 <- anti_join(nc1, same, by ="outcomeId") %>%
  select("targetId", "comparatorId", "origin", "outcomeId", "outcomeName")
nc2 <- anti_join(nc2, same, by = "outcomeId") %>%
  mutate(origin = "Glp1Dili") %>%
  mutate(targetId = 201100000) %>% 
  mutate(comparatorId = 101100000) %>%
  select("targetId", "comparatorId", "origin", "outcomeId", "outcomeName")

same <- same %>% select(targetId, comparatorId, origin, outcomeId, outcomeName) %>%
  mutate(origin = paste0(origin, "/Glp1Dili"))

out <- rbind(same, nc1, nc2)

out$cohortId <- 1000 + seq(1:nrow(out))

write.csv(out, "./inst/settings/NegativeControls.csv",
          row.names = FALSE,
          quote = FALSE)
