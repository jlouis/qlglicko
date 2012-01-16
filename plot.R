credplot.gg <- function(d){
# d is a data frame with 4 columns
# d$x gives variable names
# d$y gives center point
# d$ylo gives lower limits
# d$yhi gives upper limits
    require(ggplot2)
    p <- ggplot(d, aes(x=reorder(x, y), y=y, ymin=ylo, ymax=yhi))+geom_pointrange()+
           coord_flip() + geom_hline(aes(x=0), lty=2) + geom_hline(yintercept=1500, lty=3) + xlab('Player') +ylab('Rating')
    return(p)
}

x <- read.csv("dhw2011.csv", header=TRUE, sep=",")

d <- data.frame(x = x$Player,
                y = x$R,
                rd = x$RD)
d <- transform(d, ylo = y-2*rd, yhi=y+2*rd)

#library(plyr)
#d <- arrange(d, desc(y), desc(rd))

png("dhw2011.png")
credplot.gg(d)
dev.off()
