# Pokemon Card Grading Analysis

An R data science project that answers one practical question: **which cards in my collection are worth sending to PSA for grading?** It starts from a personal Excel tracker of ~290 cards (raw price, PSA 10 price, and estimated profit after fees) and turns it into a cleaned dataset, visual analysis, a decision framework, and a simple statistical model.

## Key findings

- **Crown Zenith is the strongest full set for grading candidates.** With 30 cards in the data, it has 13 cards flagged "Grade" and about $2,519 in total estimated profit (average about $84 per card). Among sets with 10+ cards, only "Promo" (a catch-all of mixed promos, not a single set) beats it on totals. The 151 set has a higher profit per card (about $136), but with only 17 cards.
- **Most cards are not worth grading.** Of 288 Pokemon cards, 87 are clear "Grade" calls, 186 are "Borderline" (profitable but not flagged "Yes" in my tracker), and 15 are "Don't Grade". The 87 "Grade" cards account for about $15,300 in estimated profit.
- **Raw price only partly predicts graded price.** A simple linear regression of PSA 10 price on raw price gives R-squared of about 0.42: each extra $1 of raw price is associated with about $4.42 more in PSA 10 price (intercept about $72.57, p < 0.001). Cheap raw cards can still have large graded upside, which is why ROI and profit are scored separately.
- Prices come from PriceCharting and reflect one snapshot in time, so treat all figures as estimates.

## The five phases

1. **Data cleaning** - Read the Excel tracker, standardize column names, fix data types, flag non-Pokemon cards, and add ROI and a Grade / Borderline / Don't Grade decision column.
2. **Exploratory analysis** - Profit distribution, profit by set, raw vs graded price, decision mix by set, and top cards by ROI.
3. **Decision analysis** - A profit-vs-ROI decision matrix (thresholds: $80 profit, 5x ROI), a priority grading list, and a cumulative profit curve.
4. **Statistical modeling** - Correlation matrix, linear regression of graded price on raw price, set-level predictability, and residual analysis to find cards that over- or under-perform the model.
5. **Report and GitHub polish** - `Pokemon_Grading_Report.Rmd` knits the full analysis into an HTML report, and this README documents the project.

## Project structure

```
.
|-- R/Pokemon_Cleaning_R.R          # Phases 1-4 analysis script
|-- Pokemon_Grading_Report.Rmd      # R Markdown report (Phase 5), knits to HTML
|-- data/Pokemon_Grading_Excel.xlsx # Source data (sheet "Cards")
|-- README.md
`-- .gitignore
```

## Packages

`tidyverse` (dplyr, ggplot2, forcats, readr, stringr, tidyr), `readxl`, `janitor`, `scales`, `ggrepel`, and `rmarkdown` for the report.

```r
install.packages(c("tidyverse", "readxl", "janitor", "scales", "ggrepel", "rmarkdown"))
```

## How to reproduce

1. Clone this repository and open the folder in RStudio.
2. Install the packages above.
3. Open the folder as an RStudio project (or set the working directory to the project root). The script reads `data/Pokemon_Grading_Excel.xlsx` (sheet `"Cards"`, `skip = 1`) using a relative path.
4. Run `R/Pokemon_Cleaning_R.R` from top to bottom (or line by line to inspect each step). Each plot prints to the RStudio plot pane; the summary tables print to the console.
5. To build the report, open `Pokemon_Grading_Report.Rmd` and click Knit, or run `rmarkdown::render("Pokemon_Grading_Report.Rmd")` from the project root.

## Notes and limitations

- Profit is graded (PSA 10) price minus raw price minus the grading fee; it assumes a PSA 10 result, which is not guaranteed.
- Cards I own in more than one copy appear once per copy, so a few card names repeat.
- Estimates come from a single price snapshot and a personal collection, so they are not general market advice.
