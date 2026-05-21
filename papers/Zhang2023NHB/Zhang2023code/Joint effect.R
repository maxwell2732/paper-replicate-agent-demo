# Weighted standardized scores for domains
FieldID=read.csv("FieldID_for_Lifestyles.csv");FieldID=FieldID[[1]] # significant FieldID in one domain
FieldID=c("eid",FieldID)
FieldID=FieldID[!duplicated(FieldID)]
Lifestyle=data[which(colnames(data)%in%FieldID)]

## combine data 
library(dplyr)
df=inner_join(inner_join(Lifestyle,Covariate,by="eid"),dementia_status,by="eid") 

## The independent variables are converted to dumb variables
library(tidyr)
library(dplyr)
library(caret)

dmy<-dummyVars(~.,data=df[2:ncol(Lifestyle)],sep = "",fullRank=TRUE)
b=as.data.frame(predict(dmy, df[2:ncol(Lifestyle)]))
b$eid=df$eid
b=dplyr::select(b,eid,everything())
## For HR less than 1, change the levels to make them risk factors
for (i in 2:ncol(b)) {
  b[[i]]=as.factor(b[[i]])
}
Protective_exposures=result$X[result$HR<1]
which(colnames(b)%in%Protective_exposures)
for (i in 1:length(which(colnames(b)%in%Protective_exposures))) {
  levels(b[[which(colnames(b)%in%Protective_exposures)[i]]])=list("0"=1,"1"=0)
}


## The COX model is constructed, and the weighted score is generated based on the beta value
df=inner_join(inner_join(b,Covariate,by="eid"),dementia_status,by="eid")
### Loop
library(survival)
a=colnames(df)[2:ncol(b)]
variable.names=paste0(a,collapse = "+")
FML=as.formula(paste0("Surv(dementia_days,dementia_status==1)~",variable.names,"+Covariate"))
fit.full=coxph(FML,data = df)
GSum<- summary(fit.full)
coef=as.data.frame(GSum$coefficients[,1])
coef=coef[-which(row.names(coef)%in%c("Covariate")),] 

## score
### unweighted
for (i in 2:ncol(b)) {
  b[[i]]=as.integer(b[[i]])
}
b$score_NW=rowSums(b[2:ncol(b)],na.rm = T)
b$score_NW_3=cut(b$score_NW,breaks = quantile(b$score_NW,probs = c(0,0.333,0.666,1),na.rm = T),include.lowest = TRUE)
df=inner_join(inner_join(b,Covariate,by="eid"),dementia_status,by="eid") #df=data
df=df[!(df$eid%in%exclusion),] 
fit.full=coxph(Surv(dementia_days,dementia_status==1)~score_NW_3+Covariate,data=df)
summary(fit.full)

### weighted
b_test=b[2:(ncol(b)-2)]
b_test=as.matrix(b_test)
b_test=b_test%*%diag(coef)
b_test=as.data.frame(b_test)
colnames(b_test)=colnames(b)[2:(ncol(b)-2)]
b_test$eid=b$eid
b_test=dplyr::select(b_test,eid,everything())
b_test$score_W=rowSums(b_test[2:ncol(b_test)],na.rm = T)
b_test$score_W_3=cut(b_test$score_W,breaks = quantile(b_test$score_W,probs = c(0,0.33,0.66,1),na.rm = T),include.lowest = TRUE)
df=inner_join(inner_join(b_test,Covariate,by="eid"),dementia_status,by="eid") #df=data
fit.full=coxph(Surv(dementia_days,dementia_status==1)~score_W_3+Covariate,data=df)
summary(fit.full)

