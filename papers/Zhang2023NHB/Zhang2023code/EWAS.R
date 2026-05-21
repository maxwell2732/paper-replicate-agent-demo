# 1 Data preparation
## Outcome
## Coviarate
## Independent variables
## Combine ========================
library(dply)
df=inner_join(inner_join(data,Covariate,by="eid"),dementia_status,by="eid") 

# 2 Loop =====================
library(survival)
Uni_glm_model=
  function(x){
    FML=as.formula(paste0("Surv(dementia_days,dementia_status==1)~",x,"+Covariate")) 
    glm1=coxph(FML,data=df) 
    GSum<- summary(glm1)
    coef=GSum$coefficients[,1]
    HR<- round(GSum$coefficients[,2],4)
    se=GSum$coefficients[,3]
    CI5=round(exp(coef-1.96*se),4)
    CI95=round(exp(coef+1.96*se),4)
    Pvalue<- round(GSum$coefficients[,5],6)
    p=GSum$coefficients[,5]
    instance=p
    if (class(df[[x]])=="factor") {
      instance[1:(length(levels(df[[x]]))-1)]=as.data.frame(table(df[[x]]))[[2]][2:length(levels(df[[x]]))] 
    } 
    if (class(df[[x]])!="factor") {
      instance[1]=NA 
    }
    full=p
    full[!is.na(full)]=length(na.omit(df[[x]])) 
    Field=p
    Field[!is.na(Field)]=x
    ## PH test
    PH_test=cox.zph(glm1,transform = "km")
    P_value_for_Schoenfeld_residuals=p
    if (class(df[[x]])=="factor") {
      P_value_for_Schoenfeld_residuals[1:(length(levels(df[[x]]))-1)]=as.data.frame(PH_test$table)[[3]][1]
    } 
    if (class(df[[x]])!="factor") {
     P_value_for_Schoenfeld_residuals[1]= as.data.frame(PH_test$table)[[3]][1]
    }
    
    Uni_glm_model=cbind(Field,HR,CI5,CI95,p,instance,full,P_value_for_Schoenfeld_residuals)
    Uni_glm_model=as.data.frame(Uni_glm_model)
    dimnames(Uni_glm_model)[[2]]=c("FieldID","HR","CI5","CI95","P","case","full_sample","P-value for Schoenfeld residuals")
    return(Uni_glm_model) 
  } 

variable.names=colnames(df)[2:ncol(data)] 
Uni_glm=vector(mode="list",length=length(variable.names))
Uni_glm=lapply(variable.names,Uni_glm_model)      
   


