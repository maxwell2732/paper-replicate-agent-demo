library(stdReg)
# Data preparation
## Outcome====================================
## Coviarate=================================
## Independent variable=====================
## Combine data========================
library(dplyr)
data=Joint_exposure
df=inner_join(inner_join(data,Covariate,by="eid"),dementia_status,by="eid") 

## Model 1 
df2=filter(df,df$dementia_days>=365*6)
for (i in c(2:7)) {
  levels(df2[[i]])=list("1"=1,"1"=2,"2"=3)
}
for (i in c(2:7)) {
  df2[[i]]=as.integer(df2[[i]])
}

# Model 2
df2=filter(df,df$dementia_days>=365*6)
for (i in c(2:7,15)) {
  levels(df2[[i]])=list("1"=1,"2"=2,"2"=3)
}
for (i in c(2:7,15)) {
  df2[[i]]=as.integer(df2[[i]])
}


# PAF calculation=====================

library(stdReg)
AF=function(est){
  p=est[1]
  p0=est[2]
  af=1-p0/p
  return(af)
}
Uni_glm_model=
  function(y){
    FML=as.formula(paste0("dementia_status~",y,"+Covariate"))
    glm1=glm(FML,data=df2,family="binomial") 
    fit.std <- stdGlm(fit=glm1, data=df2, X=y, x=c(NA,1)) # c(NA,0) is the value of the OR>1 variable, NA is the factual distribution, and 0 is the counterfactual distribution; The specific value of X to be written in x=c() is not necessarily 0
    AFest=AF(fit.std$est)
    a=confint(object = fit.std,fun = AF,level = 0.95)
    glm2=summary(glm1) # summary glm1
    OR=round(exp(coef(glm1)),4) # OR
    SE=coef(glm2)[,2] 
    CI5=round(exp(coef(glm1)-1.96*SE),4)
    CI95=round(exp(coef(glm1)+1.96*SE),4)
    P=coef(glm2)[,4]
    Uni_glm_model=data.frame('predictors'=y,'AF'=AFest,'CI_L'=a[1],'CI_U'=a[2],'OR'=OR,'CI5'=CI5,'CI95'=CI95,'P'=P)[-1,]
    return(Uni_glm_model)
  }
variable.names=colnames(df2)[c(2:ncol(Joint_exposure))]

Uni_glm=vector(mode="list",length=length(variable.names))
Uni_glm=lapply(variable.names,Uni_glm_model)

# weighted PAF (communality calculation)
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


