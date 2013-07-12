require(ggplot2)

gmean <- function(x) { exp(mean(log(x))) }

x <- read.csv("players.csv", header=TRUE, sep=",",stringsAsFactors=FALSE)
x <- transform(x, RDlo = R-2*RD, RDhi = R+2*RD)

pdf("matchup.pdf", height=16)
p <- ggplot(x, aes(x=reorder(Player, RDlo, gmean), y=R, ymin=RDlo, ymax=RDhi, colour=factor(Player)))
p + geom_pointrange() + facet_grid(Map ~ .) + coord_flip() + theme(strip.text.y = element_text(size = 8, colour = "black", angle = 0))
dev.off()

