#!/usr/bin/env Rscript

library(tidyverse)
library(broom)

# load dataframe
df <- read_csv("summary.csv") %>%
  mutate(ani = 100*ani,
         y = 100*n/length)

mash <- read_tsv("mash.txt", col_names = c("sample", "mock", "true_ani")) %>%
  separate_wider_delim(cols = c("mock"), delim = '_', names = c("id","ani","rep")) %>%
  mutate(true_ani = as.numeric(true_ani),
         sample = str_remove_all(id, pattern = '.ani'),
         ani = str_remove_all(ani, pattern = '.rep'),
         ani = 100*as.numeric(str_replace_all(ani, pattern = '-', replacement = '.')),
         rep = str_remove_all(rep, pattern = ".fasta")
         ) %>%
  select(sample, ani, rep, true_ani)

df <- merge(df, mash, by=c("sample","ani","rep"))

p <- ggplot(df, aes(x=ani, y=true_ani))+
  geom_point()+
  labs(x="Predicted ANI (Mash)", y = "Actual ANI")+
  theme_bw()
ggsave(plot = p, filename = "pred-vs-ani_act.jpg", dpi = 300, width = 5, height = 4)
# 
p <- df %>%
  mutate(diff = ani-true_ani) %>%
  ggplot(aes(x=ani, y=diff))+
  geom_point()+
  labs(x="Predicted ANI", y = "Difference (Actual ANI - Predicted ANI)")+
  theme_bw()
ggsave(plot = p, filename = "ani_diff.jpg", dpi = 300, width = 5, height = 4)

# https://douglas-watson.github.io/post/2018-09_exponential_curve_fitting/
fit <- nls(y ~ SSasymp(true_ani, yf, y0, log_alpha), data = df)
sink("summary.nls.txt")
summary(fit)
sink()

df.fitted <- augment(fit, newdata = data.frame(true_ani=seq(from=min(df$ani), to=max(df$ani), by = 0.0001)))
write.csv(x=df.fitted, file="df_fitted.csv", quote=F, row.names=F)

threshold <- df.fitted %>%
  filter( abs(`.fitted`) == min(abs(`.fitted`))) %>%
  filter( true_ani == max(true_ani)) %>%
  .$true_ani %>%
  as.character()
writeLines(threshold, "threshold.txt")
# output funtion from r script

# Threshold @ 0: 96.0936
cat(paste0("Threshold @ 0: ",threshold, sep = "\n"))

p <- ggplot(data = augment(fit), aes(x=as.numeric(true_ani), y=as.numeric(y)))+
  geom_point()+
  geom_line(data = df.fitted, aes(x=as.numeric(true_ani), y=as.numeric(.fitted)))+
  geom_vline(xintercept = as.numeric(threshold), linetype="dashed", color = "red")+
  theme_bw()+
  labs(x="Sample-Reference % ANI", y = "% Ambiguous Bases (N) in Consensus")
ggsave(plot = p, filename = "nls.jpg", dpi = 300, width = 5, height = 4)