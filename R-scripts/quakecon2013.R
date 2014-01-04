require(ggplot2)

gmean <- function(x) { exp(mean(log(x))) }

x <- read.csv("http://myrddraal:8080/stats/tournament/quakecon2013/75", stringsAsFactors=FALSE)
x <- transform(x, Rdlo = Rank-2*Rd, Rdhi = Rank+2*Rd)

pdf("matchup.pdf", height=24)
p <- ggplot(x, aes(x=reorder(Player, Rank, gmean), y=Rank, ymin=Rdlo, ymax=Rdhi, colour=factor(Player)))
p + geom_pointrange() + facet_grid(Map ~ .) + coord_flip() + theme(strip.text.y = element_text(size = 8, colour = "black", angle = 0))
dev.off()

