credplot.gg <- function(df){
# df is a data frame with 4 columns
# df$x gives variable names
# df$y gives center point
# df$ylo gives lower limits
# df$yhi gives upper limits
    require(ggplot2)
    p <- ggplot(df, aes(x=reorder(x, ylo), y=y, colour=Volatility, ymin=ylo, ymax=yhi)) +
      geom_pointrange() + geom_point(aes(y=ylo), colour="black", size=1.5)+coord_flip() +
      geom_hline(aes(x=0), lty=2) + geom_hline(yintercept=1500, lty=3) +
      xlab('Player') + ylab('Rating')
    return(p)
}

x <- read.csv("rel/qlglicko/rankings.csv", header=TRUE, sep=",",
              stringsAsFactors=FALSE)

d <- data.frame(x = x$Player,
                y = x$R,
                rd = x$RD,
                Volatility = x$Sigma)
d <- transform(d, ylo = y-2*rd, yhi=y+2*rd)
z <- data.frame(subset(d, y > 1850))
z$x <- factor(z$x)

#library(plyr)
#d <- arrange(d, desc(y), desc(rd))

png("rankings.png", width=1600, height=1200)
credplot.gg(z)
dev.off()
pdf("rankings.pdf", height=10)
credplot.gg(z)
dev.off()

