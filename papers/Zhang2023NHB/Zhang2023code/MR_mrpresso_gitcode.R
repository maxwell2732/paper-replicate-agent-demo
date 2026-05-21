###MR presso 

library(TwoSampleMR)
library(ieugwasr)
library(dplyr)
library(simex)
library(MRPRESSO)

setwd("/AD_phewas/MR_mrpresso")
#0.create folders
dir.create("exposure_resources")
dir.create("save_harmonise_dat")
dir.create("save_report()/")
dir.create("save_result_combine_individ/")



#----------------------------------------------------------------#
#-----------------Before analysis--------------------------------#
#----------------------------------------------------------------#

#read exposure variable description file
variablefile <- read.csv('wget_varname_link.csv')
IEU_ID <-variablefile %>% filter(IEU_WEBSITE_ID!='')%>% subset(select=c(IEU_WEBSITE_ID)) 
IEU_ID <- IEU_ID$IEU_WEBSITE_ID
IEU_ID <- as.character(IEU_ID)


#----------------------------------------------------------------#
#-----------------Start analysis---------------------------------#
#----------------------------------------------------------------#
result_combine_f <- data.frame()

for (i in IEU_ID) {
  #1. read exposure
  exposure_dat <- read.csv(paste0("/AD_phewas/MR/exposure_resources/",i,".clumped.csv")) #read previously saved clumped exposure dataset
  trait1.exposure_data_clumped <- exposure_dat
  if (!is.null(exposure_dat)) { 
    #2.read outcome
    outcome_dat <- extract_outcome_data(snps=trait1.exposure_data_clumped$SNP, outcomes="ieu-b-2")
    if (!is.null(outcome_dat)) { 
      #3.harmonise exposure and outcome
      trait1.trait2.dat  <- harmonise_data(trait1.exposure_data_clumped , outcome_dat)
      
      if(is.na(trait1.trait2.dat$samplesize.exposure[1])) {  
        trait1.trait2.dat$samplesize.exposure <- variablefile$exposure.splsize[variablefile$IEU_WEBSITE_ID==i]
      }
      
      if(is.na(trait1.trait2.dat$samplesize.outcome[1])) {  
        trait1.trait2.dat$samplesize.outcome <- 63926
      }
      #4.MR analysis and generate OR
      trait1.trait2.results <- mr(trait1.trait2.dat)
      trait1.trait2.results.withOR = generate_odds_ratios(trait1.trait2.results)##生成OR
      result_combine <- filter(trait1.trait2.results.withOR, method=='Inverse variance weighted')
      #MRPRESSO need >3 SNPs
      if (nrow(trait1.trait2.dat)>2) { 
        #MR_PRESSO
        trait1.trait2.dat.run_mr_presso = run_mr_presso(trait1.trait2.dat,NbDistribution = 8000)
        result_combine$MR_PRESSO.Results.Global.pval <- trait1.trait2.dat.run_mr_presso[[1]]$`MR-PRESSO results`$`Global Test`$Pvalue
        result_combine$Main_MR_results.Effect_Raw <- trait1.trait2.dat.run_mr_presso[[1]]$`Main MR results`$`Causal Estimate`[1]
        result_combine$Main_MR_results.Sd_Raw <- trait1.trait2.dat.run_mr_presso[[1]]$`Main MR results`$Sd[1]
        result_combine$Main_MR_results.pval_Raw <- trait1.trait2.dat.run_mr_presso[[1]]$`Main MR results`$`P-value`[1]
        result_combine$Main_MR_results.Effect_Corre <- trait1.trait2.dat.run_mr_presso[[1]]$`Main MR results`$`Causal Estimate`[2]
        result_combine$Main_MR_results.Sd_Corre <- trait1.trait2.dat.run_mr_presso[[1]]$`Main MR results`$Sd[2]
        result_combine$Main_MR_results.pval_Corre <- trait1.trait2.dat.run_mr_presso[[1]]$`Main MR results`$`P-value`[2]
        result_combine$MR_PRESSO.Results.Distortion.pval <- trait1.trait2.dat.run_mr_presso[[1]]$`MR-PRESSO results`$`Distortion Test`$Pvalue
        if (is.null(result_combine$MR_PRESSO.Results.Distortion.pval)) {result_combine$MR_PRESSO.Results.Distortion.pval <- NA}
        result_combine$MR_PRESSO.Results.Global.pval <- as.character(result_combine$MR_PRESSO.Results.Global.pval)
        result_combine$MR_PRESSO.Results.Distortion.pval <- as.character(result_combine$MR_PRESSO.Results.Distortion.pval)
        #combine results
        result_combine_f <- bind_rows(result_combine_f,result_combine)
        write.csv(result_combine_f,'/AD_phewas/MR_mrpresso/save_result_combine_individ/result_combine_run.csv',row.names=FALSE)
      }
    }
  }
}


###

