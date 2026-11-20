# FUN PROJECT ON POKEMON GRADING

# reading in the excel file
# (run from the project root so the relative path below resolves)
library(tidyverse)
library(readxl)
library(janitor)
library(scales)
library(ggrepel)
raw = read_excel("data/Pokemon_Grading_Excel.xlsx",
                 sheet = "Cards",
                 skip = 1)


#Phase 1: cleaning data

clean = raw |>
  select(-`Total Ungraded`, -`Total Graded (10)`, -Diff., -Costs...13, -Costs...16, -`Total Profit...14`, -`Total Profit...17`, - `> 70% Profit`) |>
  clean_names() |>
  select(
    id = x1,
    card_name = pokemon_name,
    set_name = set_name,
    raw_price = ungraded_price,
    graded_price = graded_price_10,
    price_increase = price_increase, 
    profit = profit,
    worth_grading = yes_or_no,
    pc_link = pc_link
  )
  

# dropping the blank rows at the bottom of the sheet (no card data)
clean <- clean |>
  filter(!is.na(card_name))

# fixing data types as a precaution
clean <- clean |>
  mutate(
    id             = as.integer(id),
    raw_price      = as.numeric(raw_price),
    graded_price   = as.numeric(graded_price),
    price_increase = as.numeric(price_increase),
    profit     = as.numeric(profit),
    worth_grading  = str_trim(worth_grading)  # Removes accidental whitespace
  )


# flagging the non-pokemon cards
non_pokemon_sets = c("OP-13", "Spider Man - Magic")
cards = clean |>
  mutate(
    is_pokemon = !set_name %in% non_pokemon_sets
  )

# Adding the decision column
# Is it worth grading for profit?

cards = cards |>
  mutate(
    roi = profit/raw_price,
    grade_decision = case_when(
      profit > 0 & worth_grading == "Yes" ~ "Grade",
      profit > 0 & worth_grading == "No"  ~ "Borderline",
      TRUE ~ "Don't Grade"
    ) 
  )


# Phase 2: creating visualizations
# Plot 1: Distribution of Raw Profit

pokemon = cards |>
  filter(is_pokemon)

avg_profit = mean(pokemon$profit)
my_threshold = 80

ggplot(pokemon, aes(x = profit)) +
  geom_histogram(binwidth = 20, fill = "#2988F5", color = "white") + 
  geom_vline(xintercept = avg_profit, color = "#f39c12", linetype = "dashed", linewidth = 1) +
  geom_vline(xintercept = my_threshold, color = "red", linetype = "dashed", linewidth = 1) +
  annotate("text", x = my_threshold, y = Inf, label = "My Threshold", fontface = "bold", color = "#062547", hjust = -0.1, vjust = 2, size = 3) +
  annotate("text", x = avg_profit, y = Inf, label = "Average Profit", fontface = "bold", color = "#062547", hjust = -0.1, vjust = 2, size = 3) +
  annotate("text", x = my_threshold, y = 0, label = paste0("$", my_threshold),   color = "#062547", fontface = "bold", hjust = -0.1, vjust = -0.5, size = 3.5) +
  annotate("text", x = avg_profit,   y = 0, label = paste0("$", round(avg_profit, 1)), color = "#062547", fontface = "bold", hjust = -0.1, vjust = -0.5, size = 3.5) +
  labs(
    title = "Distribution of Profit per Card (PSA Fee Included)",
    subtitle = "How cards stack up against key thresholds",
    x  = "Profit ($)",
    y = "Number of Cards"
  ) +
  theme_minimal()

# Plot 2: Group Spread
# Distribution of profit by set

pokemon |>
  group_by(set_name) |>
  filter(n() >= 3) |>                    
  ungroup() |>
  mutate(set_name = fct_reorder(set_name, profit, median)) |>
  ggplot(aes(x = set_name, y = profit, fill = "black")) +
  geom_boxplot(show.legend = FALSE) +
  geom_hline(yintercept = 0, color = "red", linetype = "dashed") +
  coord_flip() +
  labs(
    title    = "Profit Distribution by Set (Sets with 3+ Cards)",
    subtitle = "Sets with fewer than 3 cards excluded for reliability",
    x        = "Set Name",
    y        = "Profit ($)"
  ) +
  theme_minimal()+
  theme(
    axis.title.y = element_text( face = "bold"),
    axis.title.x = element_text(face = "bold"),
    axis.text.y = element_text(face = "bold")
  )

# Plot 3: Scatter Plot
# Raw Price vs Graded Price

ggplot(pokemon, aes(x = raw_price, y = graded_price, color = grade_decision)) +
  geom_point(size = 2.5, alpha = 0.7) +
  geom_abline(slope = 1, intercept = 0,
              color = "gray", linetype = "dashed") +
  scale_color_manual(values = c(
    "Grade"      = "#2ecc71",
    "Borderline" = "#f39c12",
    "Don't Grade" = "#e74c3c"
  )) +
  scale_x_continuous(labels = dollar_format()) +
  scale_y_continuous(labels = dollar_format()) +
  labs(
    title = "Raw Price vs Graded Price",
    subtitle = "Points above the dashed line gain value when graded",
    x = "Raw Price ($)",
    y = "Graded Price ($)",
    color = "Decision"
  ) +
  theme_minimal()

# Plot 4: Stacked Bar
# Grade Decision by Set
  
pokemon |>
  count(set_name, grade_decision) |>
  group_by(set_name) |>
  mutate(pct = n/sum(n)) |>
  ggplot(aes(x = fct_reorder(set_name, pct, max),
             y = pct,
             fill = grade_decision)) +
  geom_col() +
  coord_flip() +
  scale_y_continuous(labels = percent_format()) +
  scale_fill_manual(values = c(
    "Grade" = "#2ecc71",
    "Borderline"  = "#f39c12",
    "Don't Grade" = "#e74c3c"
  )) +
  labs(
    title = "Grade Decision Breakdown by Set",
    x = NULL,
    y = "Proportion of Cards", 
    fill = "Decision"
  ) +
  theme_minimal() +
  theme(
    axis.title.y = element_text( face = "bold"),
    axis.title.x = element_text(face = "bold"),
    axis.text.y = element_text(face = "bold"),
    axis.text.x = element_text(face = "bold")
  )

# Plot 5: Horizontal Bar
# Top 15 Cards By Set

pokemon |>
  slice_max(roi, n = 15) |>
  mutate(card_name = fct_reorder(card_name, roi)) |>
  ggplot(aes(x = roi, y = card_name)) +
  geom_col(show.legend = FALSE) +
  scale_x_continuous(labels = function(x) paste0(round(x,1))) +
  labs(
    title = "Top 15 Cards Based on ROI",
    subtitle = "ROI = net profit / raw price",
    x = "ROI",
    y = NULL
  ) +
  theme_minimal()


# Summary Table

summary = pokemon |>
  group_by(set_name) |>
  summarise(
    cards = n(),
    avg_raw = mean(raw_price),
    avg_graded = mean(graded_price),
    avg_profit = mean(profit),
    avg_roi = mean(roi), 
    grade_candidates = sum(grade_decision == "Grade")
  ) |>
  arrange(desc(avg_profit)) |>
  print(n = Inf)


# Phase 3: Decision Analysis

#Plot 1: Grading Decision Matrix

# define the thresholds
PROFIT_THRESHOLD <- 80
ROI_THRESHOLD    <- 5 

# pre-mutating the data (attempted to do all the work in one block of code instead of segments casuing bugs and errors)
pokemon_matrix <- pokemon |>
  mutate(
    quadrant = case_when(
      profit >= PROFIT_THRESHOLD & roi >= ROI_THRESHOLD ~ "Grade First",
      profit >= PROFIT_THRESHOLD & roi < ROI_THRESHOLD ~ "Grade if Capital Available",
      profit < PROFIT_THRESHOLD & roi >= ROI_THRESHOLD ~ "Monitor Price",
      TRUE ~ "Skip"
    )
  )

# pre-filter labels
labels_data <- pokemon_matrix |>
  filter(profit >= 150 | roi >= 20)

# now i can mkae the plot
ggplot(pokemon_matrix, aes(x = roi, y = profit, color = quadrant)) +
  geom_point(size = 2.5, alpha = 0.8) +
  geom_hline(yintercept = PROFIT_THRESHOLD, linetype = "dashed", color = "gray40") +
  geom_vline(xintercept = ROI_THRESHOLD, linetype = "dashed", color = "gray40") +
  geom_label_repel(
    data = labels_data,
    aes(label = card_name),
    size = 2.8,
    max.overlaps = 10
  ) +
  scale_color_manual(values = c(
    "Grade First"                = "#2ecc71",
    "Grade if Capital Available" = "#3B4CCA",
    "Monitor Price"              = "#f39c12",
    "Skip"                       = "#e74c3c"
  )) +
  scale_x_continuous(labels = function(x) paste0(round(x, 1), "x")) +
  scale_y_continuous(labels = dollar_format()) +
  labs(
    title    = "Grading Decision Matrix",
    subtitle = paste0("Profit threshold: $", PROFIT_THRESHOLD, " | ROI threshold: ", ROI_THRESHOLD, "x"),
    x        = "Return on Investment (ROI)",
    y        = "Profit ($)",
    color    = "Decision"
  ) +
  theme_minimal()


# Plot 2: Priority Grading List

# setting up the data for the graph
priority = pokemon |>
  filter(profit >= PROFIT_THRESHOLD) |>
  mutate(
    profit_norm = (profit - min(profit)) / (max(profit) - min(profit)),
    roi_norm = (roi - min(roi)) / (max(roi) - min(roi)),
    score = (profit_norm + roi_norm) / 2
  ) |>
  arrange(desc(score)) |>
  slice_head(n = 20)


# graphing

priority |>
  mutate(card_name = fct_reorder(card_name, score)) |>
  ggplot(aes(x = score, y = card_name, fill = score)) +
  geom_col() +
  scale_fill_gradient(low = "#f39c12", high = "#2ecc71") +
  scale_x_continuous(labels = percent_format()) +
  labs(
    title = "Top 20 Cards to Grade First",
    subtitle = "Ranked by combined profit + ROI score (%)",
    x = "Priority Score",
    y = NULL,
    fill = "Score"
  ) +
  theme_minimal() +
  theme(legend.position = "none")


# Plot 3: Cumulative Profit Curve

pokemon |>
  filter(profit >= PROFIT_THRESHOLD) |>
  arrange(desc(profit)) |>
  mutate(
    cards_graded = row_number(), 
    cumulative_profit = cumsum(profit)
  ) |>
  add_row(cards_graded = 0, cumulative_profit = 0, .before = 1) |>
  ggplot(aes(x = cards_graded, y = cumulative_profit)) +
  geom_line(color = "#3B4CCA", linewidth = 1.2) +
  geom_area(fill = "#3B4CCA", alpha = 0.1) +
  scale_y_continuous(labels = dollar_format(), expand = c(0,0)) +
  scale_x_continuous(labels = comma_format(), expand = c(0,0)) +
  labs(
    title = "Cumulative Profit if Cards Graded", 
    subtitle = "Cards ABove $80 Threshold Only", 
    x = "Number of Cards Graded",
    y = "Cumulative Profit ($)"
  ) +
  theme_minimal()


# SUMMARY

pokemon_matrix |>
  group_by(quadrant) |>
  summarise(
    cards        = n(),
    avg_profit   = mean(profit),
    total_profit = sum(profit),
    avg_roi      = mean(roi)
  ) |>
  arrange(desc(avg_profit))


# Phase 4: Statistical Insights and Regressions

# Correlation Matrix

# selecting the important columns
cor_data = pokemon |>
  select(raw_price, graded_price, profit, roi) |>
  cor(use = "complete.obs")

# review correlation matrix
print(round(cor_data,2))

# Plot 1: Visualization of the Correlation Matrix

cor_data |>
  as.data.frame() |>
  rownames_to_column("var1") |>
  pivot_longer(-var1, names_to = "var2", values_to = "correlation") |>
  ggplot(aes(x = var1, y = var2, fill = correlation)) +
  geom_tile(color = "white") +
  geom_text(aes(label = round(correlation, 2)), size = 4) +
  scale_fill_gradient2(
    low = "#e74c3c",
    mid = "white",
    high = "#2ecc71",
    midpoint = 0,
    limits = c(-1,1)
  ) +
  labs(
    title = "Correlation Matrix - Key Variables",
    x = NULL,
    y = NULL,
    fill = "Correlation"
  ) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))
  
  
 # Plot 2: Simple Linear Regression (Raw vs Graded Price)

model = lm(graded_price ~ raw_price, data = pokemon)
summary(model)
  
ggplot(pokemon, aes(x = raw_price, y = graded_price)) +
  geom_point(color = "#3B4CCA", alpha = 0.6, size = 2.5) +
  geom_smooth(method = "lm", color = "#2ecc71", 
              se = TRUE, linewidth = 1.2) +
  geom_label_repel(
    data = pokemon |> filter(graded_price >= 200),
    aes(label = card_name),
    size = 2.8,
    max.overlaps = 10
  ) +
  scale_x_continuous(labels = dollar_format()) +
  scale_y_continuous(labels = dollar_format()) +
  labs(
    title = "Raw Price vs Graded Price - Linear Regression",
    subtitle = paste0("R² = ", round(summary(model)$r.squared,3),
                      " | p-value < 0.05"),
    x = "Raw Price",
    y = "PSA 10 Price"
  ) +
  theme_minimal()
  
# Plot 3 - Regression by Sets

# setting up dataset

set_model = pokemon |>
  group_by(set_name) |>
  filter(n()>= 3) |>
  summarise(
    cards = n(),
    correlation = cor(raw_price, graded_price, use = "complete.obs"),
    avg_profit = mean(profit),
    avg_roi = mean(roi),
    .groups = "drop"
  ) |>
  arrange(desc(correlation))

# graphing the dataset

ggplot(set_model, aes(x = correlation, y = avg_profit, size = cards, color = avg_roi)) +
  geom_point(alpha = 0.8) +
  geom_label_repel(
    data    = set_model,
    aes(label = set_name),
    size    = 2.8,
    max.overlaps = 10
  ) +
  scale_color_gradient(low = "#e74c3c", high = "#2ecc71") +
  scale_size_continuous(range = c(3, 10)) +
  scale_x_continuous(labels = number_format(accuracy = 0.01)) +
  scale_y_continuous(labels = dollar_format()) +
  labs(
    title    = "Set Predictability vs. Average Profit",
    subtitle = "Bubble size = number of cards | Color = average ROI",
    x        = "Correlation (Raw vs Graded Price)",
    y        = "Average Profit ($)",
    color    = "Avg ROI",
    size     = "Cards in Set"
  ) +
  theme_minimal()


# Plot 4 - Profit Residuals
# which cards underperformed or overperformed

# preparing the data for the graph by creating 
pokemon =  pokemon |>
  mutate(
    predicted_grade = predict(model, newdata = pokemon),
    residual = graded_price - predicted_grade,
    beats_model = residual > 0
  )

pokemon |>
  slice_max(abs(residual),n = 20) |>
  mutate(card_name = fct_reorder(card_name, residual)) |>
  ggplot(aes(x = residual, y = card_name, fill = beats_model)) +
  geom_col() +
  scale_fill_manual(values = c("TRUE" ="#2ecc71", "FALSE" = "#e74c3c"),
                    labels = c("TRUE" = "Above Prediction", "FALSE" = "Below Prediction")) +
  scale_x_continuous(labels = dollar_format()) +
  labs(
    title = "Top 20 Cards by Regression Residual",
    subtitle = "Green = graded price exceeded model prediction | Red = fell short",
    x = "Residual",
    y = NULL,
    fill = NULL
  ) +
  theme_minimal()



summary(model)



