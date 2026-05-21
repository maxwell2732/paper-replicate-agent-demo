# Generate a correlation matrix ================================
library(psych)
for (i in c(2:7)) {
  df2[[i]]=as.integer(df2[[i]])
}
correlation=tetrachoric(df2[c(2:ncol(Joint_exposure))],na.rm=T)
cor=correlation$rho # Correlation coefficient matrix
cor.plot(cor)
dev.off()

# eigenvalues and eigenvectors
ev=eigen(cor) 
val=ev$values # eigenvalues
U=as.matrix(ev$vectors) # eigenvectors
which(val>1)
U=U[,c(1,2)] # retain eigenvalues>1

# communality
U=as.data.frame(U)
U$communality=0
for (i in 1:nrow(U)) {
  a <- c(U$V1[i],U$V2[i])
  U$communality[i]=sum(a^2)
} 
name=colnames(df2)[c(2:7)]
U$predictors=name

# combine with the result of PAF
communality=U
PAF=result
communality=U[,c("communality","predictors")]
PAF=left_join(PAF,communality,by="predictors")

# overall adjusted PAF
a=1-(1-PAF$communality)*PAF$AF
b=cumprod(a)[length(a)]
overall_PAF=1-b

# single adjusted PAF
PAF$weighted_PAF=(PAF$AF/sum(PAF$AF))*overall_PAF

