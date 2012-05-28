credplot.gg.ladder <- function(df){
# df is a data frame with 4 columns
# df$x gives variable names
# df$y gives center point
# df$ylo gives lower limits
# df$yhi gives upper limits
    require(ggplot2)
    p <- ggplot(df, aes(x=reorder(x, lr), y=y, colour=Volatility, ymin=ylo, ymax=yhi)) +
      geom_pointrange() + geom_point(aes(y=lr), colour="black", size=1.5)+coord_flip() +
      geom_hline(aes(x=0), lty=2) + geom_hline(yintercept=1500, lty=3) +
        xlab('Player') + ylab('Rating')
    return(p)
}

credplot.gg.rank <- function(df){
# df is a data frame with 4 columns
# df$x gives variable names
# df$y gives center point
# df$ylo gives lower limits
# df$yhi gives upper limits
    require(ggplot2)
    p <- ggplot(df, aes(x=reorder(x, y), y=y, colour=Volatility, ymin=ylo, ymax=yhi)) +
      geom_pointrange() + coord_flip() +
      geom_hline(aes(x=0), lty=2) + geom_hline(yintercept=1500, lty=3) +
        xlab('Player') + ylab('Rating') + scale_colour_gradient(low="darkblue", high="orange")
    return(p)
}

binhex.gg <- function(df) {
  require(ggplot2)
  p <- ggplot(df, aes(x=y, y=Volatility)) + geom_hex()
  return(p)
}

x <- read.csv("rel/qlglicko/dhs2012.csv", header=TRUE, sep=",",
              stringsAsFactors=FALSE)

d <- data.frame(x = x$Player,
                y = x$R,
                rd = x$RD,
                Volatility = x$Sigma)
d <- transform(d, ylo = y-2*rd, yhi=y+2*rd, lr=y-4*rd)
z <- data.frame(subset(d, ylo > 1675 & rd < 90))
z$x <- factor(z$x)

y <- data.frame(subset(d, y > 1900 & y < 3000))
y$x <- factor(y$x)

#library(plyr)
#d <- arrange(d, desc(y), desc(rd))

#png("rankings.png", width=1600, height=1200)
#credplot.gg(z)
#dev.off()
##pdf("ladder.pdf", height=75)
##credplot.gg.ladder(z)
##dev.off()
##pdf("rankings.pdf", height=75)
##credplot.gg.rank(y)
pdf("rankings_dhs_2012.pdf", width=15)
credplot.gg.rank(d)
dev.off()
pdf("volatility.pdf")
binhex.gg(d)
dev.off()

