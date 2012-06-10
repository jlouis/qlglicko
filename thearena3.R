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

x <- read.csv("rel/qlglicko/thearena3_rankings.csv", header=TRUE, sep=",",
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
pdf("rankings_thearena3.pdf")
credplot.gg.rank(d)
dev.off()
pdf("volatility_thearena3.pdf")
binhex.gg(d)
dev.off()

pdf("heatmap_thearena3.pdf")
hmdat <- read.csv("rel/qlglicko/thearena3_matrix.csv")
library(ggplot2)
library(reshape2)
library(plyr)
library(scales)
hmdat.m <- melt(hmdat)
hmdat.m <- ddply(hmdat.m, .(variable), transform,
                 rescale = value)
base_size <- 9
(p <- ggplot(hmdat.m, aes(variable, Name))
 + geom_tile(aes(fill = rescale), colour = "white")
 + scale_fill_gradient(low = "white", high = "steelblue")
 + theme_grey(base_size = base_size) + labs(x = "", y = "")
 + scale_x_discrete(expand = c(0, 0))
 + scale_y_discrete(expand = c(0, 0))
 + opts(axis.ticks = theme_blank(), axis.text.x = theme_text(size = base_size *
                                      0.8, angle = 330, hjust = 0, colour = "grey50")))
dev.off()

