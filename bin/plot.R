#!/usr/bin/env Rscript


install.packages("argparser")
library(tidyverse)
library(argparser)

p <- arg_parser("create visuals for Varcraft summary")
# Add command line arguments

p <- add_argument(p, "--max_ani", help="max ani difference to test", type="numeric", default=0.2)
p <- add_argument(p, "--min_ani", help="min ani difference to test", type="numeric", default=0.0)
p <- add_argument(p, "--step", help="steps between min and max values of ANI distance to test", type="numeric", default=0.02)

# Parse the command line arguments
argv <- parse_args(p)

max_ani<-(1-argv$max_ani)*100
min_ani<-(1-argv$min_ani)*100
step<-argv$step


# load dataframe
df <- read_csv("summary.csv") %>%
  mutate(y = 100*n/length)

#cash <- read_tsv("results.txt",col_names = c("name", "year_a", "ps"))

mash <- read_tsv("mash.txt", col_names = c("sample", "mock", "true_ani")) %>%
  mutate(x=100*(1-true_ani)) %>%
  select(sample, mock, true_ani, x) #list column name to select
library(stringr)
# mash <- as.data.frame.matrix(mash)
#mash.frame(
mash$sample <- sub(".[^.]+$", "", mash$sample)

# Get rid of reference specific data
split_fname<-do.call("rbind", strsplit(as.character(mash$mock), ".", fixed = TRUE))
#split_fname1<-do.call("rbind", strsplit(as.character(mash$mock), ".", fixed = TRUE))
split_fname<-as.data.frame(split_fname)
split_fname<-split_fname %>% select(tail(names(.),3))

colnames(split_fname)[1] <- "est_ani"
est_ani<-do.call("rbind", strsplit(as.character(split_fname$est_ani), "_", fixed = TRUE))
est_ani <- est_ani[,-1]
est_ani<-as.data.frame(est_ani)
est_ani <- gsub('-', '.', est_ani$est_ani)
est_ani<-as.data.frame(est_ani)

colnames(split_fname)[2] <- "rep"
rep<-do.call("rbind", strsplit(as.character(split_fname$rep), "_", fixed = TRUE))
rep <- rep[,-1]
rep<-as.data.frame(rep)
rep<- gsub('-', '.', rep$rep)
rep<-as.data.frame(rep)
rep <- rep %>%  
  mutate(rep = as.numeric(rep))

# Fix errant rounding issues
mash <- mash %>% 
  mutate(est_ani=est_ani$est_ani, rep=rep$rep, ani=100*(as.numeric(est_ani))/100) %>%
  select(sample, ani, rep, true_ani)  #%>% mutate(sample=fasta$fasta)

df <- merge(df, mash, by=c("sample","ani","rep")) %>% unique()

p <- ggplot(df, aes(x=100*ani, y=true_ani))+
  geom_point()+
  labs(x="Predicted ANI (Mash)", y = "Actual ANI")+
  theme_bw()
ggsave(plot = p, filename = "pred-vs-ani_act.jpg", dpi = 300, width = 5, height = 4)
# 
p <- df %>%
  mutate(diff = 100*ani-true_ani) %>%
  ggplot(aes(x=100*ani, y=diff))+
  geom_point()+
  labs(x="Predicted ANI", y = "Difference (Actual ANI - Predicted ANI)")+
  theme_bw()
ggsave(plot = p, filename = "ani_diff.jpg", dpi = 300, width = 5, height = 4)



# https://douglas-watson.github.io/post/2018-09_exponential_curve_fitting/
fit <- nls(y ~ SSasymp(true_ani, yf, y0, log_alpha), data = df)
sink("summary.nls.txt")
summary(fit)
sink()


#newdata = data.frame(x=seq(from=80, to=100, by = 0.0001))
# this needs to be less hard coded

decimalplaces <- function(x) {
  if ((x %% 1) != 0) {
    nchar(strsplit(sub('0+$', '', as.character(x)), ".", fixed=TRUE)[[1]][[2]])
  } else {
    return(0)
  }
}


df.fitted <- augment(fit, newdata = data.frame(true_ani=seq(from=max_ani, to=min_ani, by = 10^(-decimalplaces(step)-2))))


# df_fitted <- df.fitted %>%
#   filter(true_ani == 80 | true_ani == 85 | true_ani == 90 | true_ani == 95) %>%
#   rename(ANI=1,
#          Predicted_Amb=2)

write.csv(x=df.fitted, file="df_fitted.csv", quote=F, row.names=F)

threshold <- df.fitted %>%
  filter( abs(`.fitted`) == min(abs(`.fitted`))) %>%
  filter( true_ani == max(true_ani)) %>%
  .$true_ani
# output funtion from r script

# Threshold @ 0: 96.0936
cat(paste0("Threshold @ 0: ",threshold, sep = "\n"))

p <- ggplot(data = augment(fit), aes(x=true_ani, y=y))+
  geom_point()+
  geom_line(data = df.fitted, aes(x=true_ani, y=.fitted))+
  geom_vline(xintercept = threshold, linetype="dashed", color = "red")+
  theme_bw()+
  labs(x="Sample-Reference % ANI", y = "% Ambiguous Bases (N) in Consensus")
ggsave(plot = p, filename = "nls.jpg", dpi = 300, width = 5, height = 4)