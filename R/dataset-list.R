source(here::here("R", "entities.R"))

datasets <- c(
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
             region_scale = "State"),
  SuperRegion$new(name = "cases",
                  case_modifier = function(cases) {
                    cases <- cases[, .(region = country, date = as.Date(date), confirm = cases_new)]
                    cases <- cases[date <= Sys.Date()]
                    cases <- cases[, .SD[date <= (max(date) - lubridate::days(3))], by = region]
                    cases <- cases[, .SD[date >= (max(date) - lubridate::weeks(12))], by = region]
                    data.table::setorder(cases, date)
                    return(cases)
                  }),
  SuperRegion$new(name = "deaths",
                  case_modifier = function(deaths) {
                    deaths <- deaths[country != "Cases_on_an_international_conveyance_Japan"]
                    deaths <- deaths[, .(region = country, date = as.Date(date), confirm = deaths_new)]
                    deaths <- deaths[date <= Sys.Date()]
                    deaths <- deaths[, .SD[date <= (max(date) - lubridate::days(3))], by = region]
                    deaths <- deaths[, .SD[date >= (max(date) - lubridate::weeks(12))], by = region]
                    data.table::setorder(deaths, date)
                    return(cases)
                  })
)