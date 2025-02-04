library(readxl)
library(dplyr)
library(tidyr)
library(ggplot2)

file_path <- "df_studenti.xlsx"
data <- read_excel(file_path, sheet = 2)

data <- data %>%
  filter(colore_stringa != "nullo")

#Moda
calculate_mode <- function(x) {
  uniq_vals <- unique(na.omit(x)) # Rimuove NA
  if (length(uniq_vals) == 0) return(NA) # Gestione dei casi senza valori
  uniq_vals[which.max(tabulate(match(x, uniq_vals)))]
}

#Moda per colore_stringa e turn
modes_by_group_turn <- data %>%
  group_by(colore_stringa, turn) %>%
  summarise(
    moda_sim_facile = calculate_mode(na.omit(sim_facile)),
    moda_sim_interessante = calculate_mode(na.omit(sim_interessante)),
    moda_sim_imparato = calculate_mode(na.omit(sim_imparato)),
    .groups = "drop"
  )

print("Mode Table by Group and Turn:")
print(modes_by_group_turn)

#Mean
means_by_group_turn <- data %>%
  group_by(colore_stringa, turn) %>%
  summarise(
    media_sim_facile = mean(na.omit(sim_facile), na.rm = TRUE),
    media_sim_interessante = mean(na.omit(sim_interessante), na.rm = TRUE),
    media_sim_imparato = mean(na.omit(sim_imparato), na.rm = TRUE),
    .groups = "drop"
  )

print("Mean Table by Group and Turn:")
print(means_by_group_turn)

#Long format
modes_by_group_turn_long <- modes_by_group_turn %>%
  pivot_longer(cols = starts_with("moda"), names_to = "Variabile", values_to = "Moda")

group_colors <- c("azzurro" = "cyan", "blu" = "blue", "giallo" = "yellow", "rosa" = "pink", "rosso" = "red")

means_by_group_turn_long <- means_by_group_turn %>%
  pivot_longer(cols = starts_with("media"), names_to = "Variabile", values_to = "Media")


# Plot separati per turn
unique_turns <- unique(modes_by_group_turn_long$turn)
for (turn in unique_turns) {
  plot_data <- modes_by_group_turn_long %>% filter(turn == !!turn)
  
  p <- ggplot(plot_data, aes(x = colore_stringa, y = Moda, fill = colore_stringa)) +
    geom_bar(stat = "identity", position = "dodge") +
    scale_fill_manual(values = group_colors) +
    facet_wrap(~Variabile, scales = "free") +
    labs(
      title = paste("Mode by group", turn),
      x = "Group",
      y = "Mode"
    ) +
    theme_minimal() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
  
  print(p)
}

data <- data %>%
  filter(colore_stringa != "nullo")

#Plot separati per turn_Mean
unique_turns <- unique(means_by_group_turn_long$turn)
for (turn in unique_turns) {
  plot_data <- means_by_group_turn_long %>% filter(turn == !!turn)
  
  p <- ggplot(plot_data, aes(x = colore_stringa, y = Media, fill = colore_stringa)) +
    geom_bar(stat = "identity", position = "dodge") +
    scale_fill_manual(values = group_colors) +
    facet_wrap(~Variabile, scales = "free") +
    labs(
      title = paste("Mean by group", turn),
      x = "Group",
      y = "Mean"
    ) +
    theme_minimal() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
  
  print(p)
}

# Collaborazione - Gruppo 1, 2, 3
data <- data %>%
  rowwise() %>%
  mutate(media_individuale_collab = mean(c_across(starts_with("collab_gruppo_")), na.rm = TRUE)) %>%
  ungroup()

results_by_group_collab <- data %>%
  group_by(colore_stringa, turn) %>%
  summarise(media_di_gruppo_collab = mean(media_individuale_collab, na.rm = TRUE), .groups = "drop")

print("Collaboration Mean Table by Group and Turn:")
print(results_by_group_collab)

#Plot
for (turn in unique(results_by_group_collab$turn)) {
  plot_data <- results_by_group_collab %>% filter(turn == !!turn)
  
  p <- ggplot(plot_data, aes(x = colore_stringa, y = media_di_gruppo_collab, fill = colore_stringa)) +
    geom_bar(stat = "identity") +
    scale_fill_manual(values = group_colors) + 
    labs(
      title = paste("Collaboration means by Group", turn),
      x = "Group",
      y = "Means"
    ) +
    theme_minimal() +
    theme(legend.position = "none")
  
  print(p)
}


#MEAN_Collaborazione - Gruppo 1, 2, 3
data <- data %>%
  rowwise() %>%
  mutate(media_individuale_collab = mean(c_across(starts_with("collab_gruppo_")), na.rm = TRUE)) %>%
  ungroup()

results_by_group_collab <- data %>%
  group_by(colore_stringa, turn) %>%
  summarise(media_di_gruppo_collab = mean(media_individuale_collab, na.rm = TRUE), .groups = "drop")

print("Collaboration Mean Table by Group and Turn:")
print(results_by_group_collab)

#Plot_MEAN
for (turn in unique(results_by_group_collab$turn)) {
  plot_data <- results_by_group_collab %>% filter(turn == !!turn)
  
  p <- ggplot(plot_data, aes(x = colore_stringa, y = media_di_gruppo_collab, fill = colore_stringa)) +
    geom_bar(stat = "identity") +
    scale_fill_manual(values = group_colors) + 
    labs(
      title = paste("Collaboration means by Group", turn),
      x = "Group",
      y = "Means"
    ) +
    theme_minimal() +
    theme(legend.position = "none")
  
  print(p)
}

#Comp_sost_Ricodifica variabili
data <- data %>%
  mutate(
    comp_sost_1 = 6 - comp_sost_1,  
    comp_sost_5 = 6 - comp_sost_5  
  )

results_by_group_compSost <- data %>%
  group_by(colore_stringa, turn) %>%
  summarise(across(starts_with("comp_sost"), ~mean(.x, na.rm = TRUE), .names = "media_{.col}"), .groups = "drop")

print("Comp_Sost Mean Table by Group and Turn:")
print(results_by_group_compSost)

#Plot
results_by_group_compSost_long <- results_by_group_compSost %>%
  pivot_longer(cols = starts_with("media"), names_to = "Variabile", values_to = "Media")

for (turn in unique(results_by_group_compSost_long$turn)) {
  plot_data <- results_by_group_compSost_long %>% filter(turn == !!turn)
  
  p <- ggplot(plot_data, aes(x = colore_stringa, y = Media, fill = colore_stringa)) +
    geom_bar(stat = "identity", position = "dodge") +
    scale_fill_manual(values = group_colors) +
    facet_wrap(~Variabile, scales = "free") +
    labs(
      title = paste("Comp_Sost Means by Group - Turn", turn),
      x = "Group",
      y = "Mean",
      fill = "Group"
    ) +
    theme_minimal() +
    theme(axis.text.x = element_text(angle = 60, hjust = 1))
  
  print(p)
}

#Comp_Sost2
data <- data %>%
  rowwise() %>%
  mutate(somma_individuale_comp_sost2 = sum(c_across(starts_with("comp_sost2_")), na.rm = TRUE)) %>%
  ungroup()

results_by_group_Comp_Sost2 <- data %>%
  group_by(colore_stringa, turn) %>%
  summarise(media_di_gruppo = mean(somma_individuale_comp_sost2, na.rm = TRUE), .groups = "drop")

print("Comp_Sost2 Mean Table by Group and Turn:")
print(results_by_group_Comp_Sost2)

#Plot
for (turn in unique(results_by_group_Comp_Sost2$turn)) {
  plot_data <- results_by_group_Comp_Sost2 %>% filter(turn == !!turn)
  
  p <- ggplot(plot_data, aes(x = colore_stringa, y = media_di_gruppo, fill = colore_stringa)) +
    geom_bar(stat = "identity") +
    scale_fill_manual(values = group_colors) +
    labs(
      title = paste("Comp_Sost2 Means by Group - Turn", turn),
      x = "Group",
      y = "Means"
    ) +
    theme_minimal() +
    theme(legend.position = "none")
  
  print(p)
}

#Collaborazione Classe_1
data <- data %>%
  rowwise() %>%
  mutate(somma_individuale_collab_classe1 = sum(c_across(starts_with("collab_classe1_")), na.rm = TRUE)) %>%
  ungroup()

results_by_group_CollabClasse <- data %>%
  group_by(colore_stringa, turn) %>%
  summarise(media_somma_collab_classe1 = mean(somma_individuale_collab_classe1, na.rm = TRUE), .groups = "drop")

print("Collaboration Class 1 Table by Group and Turn:")
print(results_by_group_CollabClasse)

#Plot
for (turn in unique(results_by_group_CollabClasse$turn)) {
  plot_data <- results_by_group_CollabClasse %>% filter(turn == !!turn)
  
  p <- ggplot(plot_data, aes(x = colore_stringa, y = media_somma_collab_classe1, fill = colore_stringa)) +
    geom_bar(stat = "identity") +
    scale_fill_manual(values = group_colors) +
    labs(
      title = paste("Collaboration_class1 Means by Group - Turn", turn),
      x = "Group",
      y = "Mean"
    ) +
    theme_minimal() +
    theme(legend.position = "none")
  
  print(p)
}

#Collaborazione Classe_2
data <- data %>%
  mutate(
    collab_classe2_2 = 6 - collab_classe2_2, 
    collab_classe2_5 = 6 - collab_classe2_5,
    collab_classe2_6 = 6 - collab_classe2_6
  ) %>%
  rowwise() %>%
  mutate(media_individuale_collab_classe2 = mean(c_across(starts_with("collab_classe2_")), na.rm = TRUE)) %>%
  ungroup()

media_complessiva_per_gruppo <- data %>%
  group_by(colore_stringa, turn) %>%
  summarise(media_complessiva = mean(media_individuale_collab_classe2, na.rm = TRUE), .groups = "drop")

print("Collaboration Class_2 Table by Group and Turn:")
print(media_complessiva_per_gruppo)

#Plot
for (turn in unique(media_complessiva_per_gruppo$turn)) {
  plot_data <- media_complessiva_per_gruppo %>% filter(turn == !!turn)
  
  p <- ggplot(plot_data, aes(x = colore_stringa, y = media_complessiva, fill = colore_stringa)) +
    geom_bar(stat = "identity") +
    scale_fill_manual(values = group_colors) +
    labs(
      title = paste("Class Collaboration_2: means by group -", turn),
      x = "Group",
      y = "Mean"
    ) +
    theme_minimal() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
  
  print(p)
}

