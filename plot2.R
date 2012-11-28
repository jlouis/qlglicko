credplot.gg.ladder <- function(df, t){
# df is a data frame with 4 columns
# df$x gives variable names
# df$y gives center point
# df$ylo gives lower limits
# df$yhi gives upper limits
    require(ggplot2)
    p <- ggplot(df, aes(x=reorder(x, lr), y=y, ymin=ylo, ymax=yhi)) +
      geom_pointrange() + geom_point(aes(y=lr), colour="black", size=1.5)+coord_flip() +
      geom_hline(aes(x=0), lty=2) + geom_hline(yintercept=1500, lty=3) +
        xlab('Player') + ylab('Glicko Rating') + ggtitle(t)
    return(p)
}

credplot.gg.rank <- function(df, t){
# df is a data frame with 4 columns
# df$x gives variable names
# df$y gives center point
# df$ylo gives lower limits
# df$yhi gives upper limits
    require(ggplot2)
    p <- ggplot(df, aes(x=reorder(x, y), y=y, ymin=ylo, ymax=yhi)) +
      geom_pointrange() + geom_point(aes(y=ylo), colour="black", size=1.5)+coord_flip() +
      geom_hline(aes(x=0), lty=2) + geom_hline(yintercept=1500, lty=3) +
        xlab('Player') + ylab('Glicko Rating') + ggtitle(t)
    return(p)
}

binhex.gg <- function(df) {
  require(ggplot2)
  p <- ggplot(df, aes(x=y, y=Volatility)) + geom_hex()
  return(p)
}

##First read in the arguments listed at the command line
args=(commandArgs(TRUE))

##args is now a list of character vectors
## First check to see if arguments are passed.
## Then cycle through each element of the list and evaluate the expressions.
if(length(args)==0){
    print("No arguments supplied.")
    ##supply default values
    title = "All rankings"
    output_rankings = "rankings.pdf"
    output_ladder = "ladder.pdf"
    limit=1900
    rd_limit=90
    f = "rel/qlglicko/rankings.csv"
} else {
    for(i in 1:length(args)){
         eval(parse(text=args[[i]]))
    }
}

x <- read.csv(f, header=TRUE, sep=",",
              stringsAsFactors=FALSE)

d <- data.frame(x = x$Player,
                y = x$R,
                rd = x$RD,
                Volatility = x$Sigma)
d <- transform(d, ylo = y-2*rd, yhi=y+2*rd, lr=y-4*rd)
z <- data.frame(subset(d, ylo > limit & rd < rd_limit))
z$x <- factor(z$x)

print(rd_limit)

y <- data.frame(subset(d, y > limit & y < 3000 & rd < rd_limit))
y$x <- factor(y$x)

#library(plyr)
#d <- arrange(d, desc(y), desc(rd))

#png("rankings.png", width=1600, height=1200)
#credplot.gg(z)
#dev.off()
pdf(output_ladder, height=75)
credplot.gg.ladder(z, title)
dev.off()
pdf(output_rankings, height=75)
credplot.gg.rank(y, title)
dev.off()
pdf("volatility.pdf")
binhex.gg(d)
dev.off()

