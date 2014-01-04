require(ggplot2)

gmean <- function(x) { exp(mean(log(x))) }

x <- read.csv("players.csv", header=TRUE, sep=",",stringsAsFactors=FALSE)
x <- transform(x, RDlo = rank-2*rd, RDhi = rank+2*rd)

pdf("matchup.pdf", height=16)
p <- ggplot(x, aes(x=reorder(player, RDlo, gmean), y=rank, ymin=RDlo, ymax=RDhi, colour=factor(player)))
p + geom_pointrange() + facet_grid(map ~ .) + coord_flip() + theme(strip.text.y = element_text(size = 8, colour = "black", angle = 0))
dev.off()

