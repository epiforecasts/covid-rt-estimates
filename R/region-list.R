source(here::here("R", "region-entity.R"))

regions <- c(
  Region$new(name = "afghanistan",
             case_modifier = function(cases) {
               cases <- cases[!is.na(iso_3166_2)]
               return(cases)
             },
             stable = FALSE),
  Region$new(name = "belgium"),
  Region$new(name = "brazil"),
  Region$new(name = "canada"),
  Region$new(name = "colombia"),
  Region$new(name = "germany"),
  Region$new(name = "india"),
  Region$new(name = "italy"),
  Region$new(name = "russia"),
  Region$new(name = "united-kingdom",
             covid_regional_data_identifier = "UK"),
  Region$new(name = "united-states",
             covid_regional_data_identifier = "USA",
             region_scale = "State")
)