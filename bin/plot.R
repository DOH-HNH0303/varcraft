library(tidyverse)
library(broom)

# load dataframe
df <- read_csv("summary.csv") %>%
  mutate(y = 100*n/length)

mash <- read_csv("mash.csv") %>%
  rename(sample=1,
        ani = 2,
        rep=3,
        dist=4)%>%
  mutate(x=100*(1-dist)) %>%
  select(sample, ani, rep, x)

df <- left_join(df, mash, by = c("sample","ani","rep")) %>%
  unique()

p <- ggplot(df, aes(x=100*ani, y=x))+
  geom_point()+
  labs(x="Actual ANI", y = "Estimated ANI (Mash)")+
  theme_bw()
ggsave(plot = p, filename = "ani_act-vs-est.jpg", dpi = 300, width = 5, height = 4)

p <- df %>%
  mutate(diff = 100*ani-x) %>%
  ggplot(aes(x=ani, y=diff))+
  geom_point()+
  labs(x="Actual ANI", y = "Difference (Actual ANI - Estimated ANI)")+
  theme_bw()
ggsave(plot = p, filename = "ani_diff.jpg", dpi = 300, width = 5, height = 4)



# https://douglas-watson.github.io/post/2018-09_exponential_curve_fitting/      
fit <- nls(y ~ SSasymp(x, yf, y0, log_alpha), data = df)
summary(fit)

df.fitted <- augment(fit, newdata = data.frame(x=seq(from=80, to=100, by = 0.0001)))

df.fitted %>%
  filter(x == 80 | x == 85 | x == 90 | x == 95) %>%
  rename(ANI=1,
         Predicted_Amb=2)

threshold <- df.fitted %>%
  filter( abs(`.fitted`) == min(abs(`.fitted`))) %>%
  filter( x == max(x)) %>%
  .$x

cat(paste0("Threshold @ 0: ",threshold, sep = "\n"))

p <- ggplot(data = augment(fit), aes(x=x, y=y))+
  geom_point()+
  geom_line(data = df.fitted, aes(x=x, y=.fitted))+
  geom_vline(xintercept = threshold, linetype="dashed", color = "red")+
  theme_bw()+
  labs(x="Sample-Reference % ANI", y = "% Ambiguous Bases (N) in Consensus")
ggsave(plot = p, filename = "nls.jpg", dpi = 300, width = 5, height = 4)


