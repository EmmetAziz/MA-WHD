# R/01_scrape_govuk.R
# ------------------------------------------------------------
# Scrape GOV.UK search results for Warm Home Discount releases
# and save a timeline CSV ready for manual annotation.
# ------------------------------------------------------------

# ── packages ────────────────────────────────────────────────
if (!requireNamespace("rvest",   quietly = TRUE)) install.packages("rvest")
if (!requireNamespace("purrr",   quietly = TRUE)) install.packages("purrr")
if (!requireNamespace("dplyr",   quietly = TRUE)) install.packages("dplyr")
if (!requireNamespace("lubridate", quietly = TRUE)) install.packages("lubridate")
if (!requireNamespace("here",    quietly = TRUE)) install.packages("here")

library(rvest)
library(purrr)
library(dplyr)
library(lubridate)
library(here)

# ── helper function: scrape one page ────────────────────────
scrape_page <- function(url) {
  read_html(url) %>%                               # whole page HTML
    html_elements(".gem-c-document-list__item") %>%
    map_dfr(\(.item) {
      tibble(
        title = .item %>%                          # release headline
          html_element(".gem-c-document-list__item-title") %>%
          html_text2(),

        date  = .item %>%                          # publication date (may be NA)
          html_element("time") %>%
          html_attr("datetime") %>%
          ymd(),

        link  = .item %>%                          # absolute URL
          html_element(".gem-c-document-list__item-title") %>%
          html_attr("href") %>%
          paste0("https://www.gov.uk", .),

        source = "GOV.UK",                         # constant
        statistical_claim = NA_character_,         # blanks for later coding
        policy_frame      = NA_character_
      )
    })
}

# ── build URL vector for the first 3 pages ─────────────────
base_url <- "https://www.gov.uk/search/all?keywords=%22Warm+Home+Discount%22&order=published-at&page="
pages    <- paste0(base_url, 1:3)

# ── scrape & combine ───────────────────────────────────────
timeline <- map_dfr(pages, scrape_page)

# ── save to CSV ────────────────────────────────────────────
out_path <- here("data", "raw", "policy_timeline_govuk.csv")
write_csv(timeline, out_path)

message("Saved ", nrow(timeline), " rows to:\n", out_path)
