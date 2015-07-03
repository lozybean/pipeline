Args <- commandArgs()
otu_file = Args[6]
out_pre = Args[7]
library(VennDiagram)
library(grid)
X=read.table(otu_file,sep="\t",row.name=1,header=F)
gnum=nrow(X)
guniq=rownames(X)
g=c()
for (i in 1:nrow(X)){
    a=X[i,]
    a=as.vector(a)
    a=strsplit(a," ")
    g=c(g,a)
}
if(gnum==2){
venn.plot <- venn.diagram(
    x = list(guniq[1]=g[1][[1]],guniq[2]=g[2][[1]]),
    filename = paste(out_pre,".venn.tiff",sep=""),
    col = "black",
    fill = c("dodgerblue", "goldenrod1"),
    cat.col = c("dodgerblue", "goldenrod1"),
    cat.cex = 1.5,
    cat.fontface = "bold",
    margin = 0.14
	)
}
if(gnum==3){
venn.plot <- venn.diagram(
        x = list(guniq[1]=g[1][[1]],guniq[2]=g[2][[1]],guniq[3]=g[3][[1]]),
        filename = paste(out_pre,".venn.tiff",sep=""),
        col = "black",
        fill = c("dodgerblue", "goldenrod1","darkorange1"),
        cat.col = c("dodgerblue", "goldenrod1","darkorange1"),
        cat.cex = 1.5,
        cat.fontface = "bold",
        margin = 0.14
        )
}
if(gnum==4){
venn.plot <- venn.diagram(
        x = list(guniq[1]=g[1][[1]],guniq[2]=g[2][[1]],guniq[3]=g[3][[1]],guniq[4]=g[4][[1]]),
        filename = paste(out_pre,".venn.tiff",sep=""),
        col = "black",
        fill = c("dodgerblue", "goldenrod1","darkorange1","seagreen3"),
        cat.col = c("dodgerblue", "goldenrod1","darkorange1","seagreen3"),
        cat.cex = 1.5,
        cat.fontface = "bold",
        margin = 0.14
        )
}
if(gnum==5){
venn.plot <- venn.diagram(
        x = list(guniq[1]=g[1][[1]],guniq[2]=g[2][[1]],guniq[3]=g[3][[1]],guniq[4]=g[4][[1]],guniq[5]=g[5][[1]]),
        filename = paste(out_pre,".venn.tiff",sep=""),
        col = "black",
        fill = c("dodgerblue", "goldenrod1", "darkorange1", "seagreen3", "orchid3"),
        cat.col = c("dodgerblue", "goldenrod1","darkorange1","seagreen3", "orchid3"),
    cex = c(1.5, 1.5, 1.5, 1.5, 1.5, 1, 0.8, 1, 0.8, 1, 0.8, 1, 0.8,1, 0.8, 1, 0.55, 1, 0.55, 1, 0.55, 1, 0.55, 1, 0.55, 1, 1, 1, 1, 1, 1.5),
        cat.cex = 1.5,
        cat.fontface = "bold",
        margin = 0.14
        )
}

