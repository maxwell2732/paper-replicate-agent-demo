#MR analysis
#mrpresso was performed seperately in another script for its low processing speed

library(TwoSampleMR)
library(ieugwasr)
library(dplyr)
library(simex)

setwd("/AD_phewas/MR")  
#0.0 create folders
dir.create("exposure_resources")
dir.create("save_harmonise_dat")
dir.create("save_report()")
dir.create("save_result_combine_individ")
#0.0 END

#0.1 setting for local clump

#https://mrcieu.github.io/ieugwasr/articles/local_ld.html
devtools::install_github("explodecomputer/genetics.binaRies")
genetics.binaRies::get_plink_binary()
#put the 1kg plink file in ‘/AD_phewas/1000G_reference_pannal/EUR/’

#0.1 END

#----------------------------------------------------------------#
#----------------- Befor analysis--------------------------------#
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
df_norun <- data.frame()
for (i in IEU_ID) {
  #1.read exposure
  exposure_dat<- extract_instruments(i,clump = FALSE)
  if (!is.null(exposure_dat)) { 
    trait1.exposure_data <- exposure_dat
    write.csv(trait1.exposure_data,paste0("/AD_phewas/MR/exposure_resources/",i,".csv"),row.names = FALSE)
    #local_clump
    trait1.exposure_data <- rename(trait1.exposure_data,
                                   rsid=SNP, 
                                   pval=pval.exposure,
                                   trait_id=id.exposure)
    trait1.exposure_data_clumped <- ld_clump(trait1.exposure_data,
                                             bfile="/AD_phewas/MR/1000G_reference_pannal/EUR/EUR",      
                                             plink_bin = genetics.binaRies::get_plink_binary())#
    trait1.exposure_data_clumped <- rename(trait1.exposure_data_clumped,
                                           SNP=rsid, 
                                           pval.exposure=pval,
                                           id.exposure=trait_id)
    write.csv(trait1.exposure_data_clumped,paste0("/AD_phewas/MR/exposure_resources/",i,".clumped.csv"),row.names = FALSE)
    #local_clump.end
    
    #2.read outcome
    outcome_dat <- extract_outcome_data(snps=trait1.exposure_data_clumped$SNP, outcomes="ieu-b-2")
    if (!is.null(outcome_dat)) { 
      #3.harmonise exposure and outcome
      trait1.trait2.dat  <- harmonise_data(trait1.exposure_data_clumped , outcome_dat)
      
      if(is.na(trait1.trait2.dat$samplesize.exposure[1])) {  
        trait1.trait2.dat$samplesize.exposure <- variablefile$exposure.splsize[variablefile$IEU_WEBSITE_ID==i]
      }
      
      if(is.na(trait1.trait2.dat$samplesize.outcome[1])) {  
        trait1.trait2.dat$samplesize.outcome <- variablefile$exposure.outsize[variablefile$IEU_WEBSITE_ID==i]
      }
      write.csv(trait1.trait2.dat,paste0("/AD_phewas/MR/save_harmonise_dat/",i,"-ieu-b-2.harmonise.csv"),row.names = FALSE)
      #4.MR analysis and generate OR
      trait1.trait2.results <- mr(trait1.trait2.dat)
      trait1.trait2.results.withOR = generate_odds_ratios(trait1.trait2.results)
      
      
      #depends on SNP counts
      if (nrow(trait1.trait2.dat)>1) { 
        #5.turn the results into one row
        result_combine <- filter(trait1.trait2.results.withOR, method=='Inverse variance weighted')
        result_MREGGER <- filter(trait1.trait2.results.withOR, method=='MR Egger')
        result_WMe <- filter(trait1.trait2.results.withOR, method=='Weighted median')
        result_WMo<- filter(trait1.trait2.results.withOR, method=='Weighted mode')
        result_SM <- filter(trait1.trait2.results.withOR, method=='Simple mode')
        result_combine <- left_join(result_combine,result_MREGGER,by=c("id.exposure","id.outcome","outcome","exposure"))
        result_combine <- left_join(result_combine,result_WMe,by=c("id.exposure","id.outcome","outcome","exposure"))
        result_combine <- left_join(result_combine,result_WMo,by=c("id.exposure","id.outcome","outcome","exposure"))
        result_combine <- left_join(result_combine,result_SM,by=c("id.exposure","id.outcome","outcome","exposure"))
        
        #6.MR-EGGER INTERCEPT
        trait1.trait2.dat.mr_pleiotropy_test = mr_pleiotropy_test(trait1.trait2.dat)
        result_combine$egger_intercept <- trait1.trait2.dat.mr_pleiotropy_test$egger_intercept
        result_combine$egger_intercept.pval <-  trait1.trait2.dat.mr_pleiotropy_test$pval
        
        if (nrow(trait1.trait2.dat)>2) { #MR-EGGER/MR-EGGER heterogeneity need at least three SNPs
          #7.MR-EGGER SIMEX
          BetaYG = trait1.trait2.dat$beta.outcome
          BetaXG = trait1.trait2.dat$beta.exposure
          seBetaYG = trait1.trait2.dat$se.outcome
          seBetaXG = trait1.trait2.dat$se.exposure
          Fit2 = lm(BetaYG~BetaXG,weights=1/seBetaYG^2,x=TRUE,y=TRUE)
          mod.sim <- simex(Fit2,B=1000,measurement.error = seBetaXG,SIMEXvariable="BetaXG",fitting.method ="quad",asymptotic="FALSE")
          summary(mod.sim)
          simex.beta = summary(mod.sim)[[1]]$jackknife[2]
          simex.se = summary(mod.sim)[[1]]$jackknife[4]
          simex.p = summary(mod.sim)[[1]]$jackknife[8]
          result_combine$isq = Isq(trait1.trait2.results$b[trait1.trait2.results$method == 'MR Egger'],trait1.trait2.results$se[trait1.trait2.results$method == 'MR Egger'])
          result_combine$simex.beta <- simex.beta 
          result_combine$simex.se <- simex.se
          result_combine$simex.p <- simex.p
          #8.HETERO
          trait1.trait2.dat.mr_heterogeneity = mr_heterogeneity(trait1.trait2.dat)
          result_combine$MR_Egger.Q <- trait1.trait2.dat.mr_heterogeneity$Q[trait1.trait2.dat.mr_heterogeneity$method == 'MR Egger']
          result_combine$MR_Egger.Q_df <- trait1.trait2.dat.mr_heterogeneity$Q_df[trait1.trait2.dat.mr_heterogeneity$method == 'MR Egger']
          result_combine$MR_Egger.Q_pval <- trait1.trait2.dat.mr_heterogeneity$Q_pval[trait1.trait2.dat.mr_heterogeneity$method == 'MR Egger']
          result_combine$Inverse_variance_weighted.Q <- trait1.trait2.dat.mr_heterogeneity$Q[trait1.trait2.dat.mr_heterogeneity$method == 'Inverse variance weighted']
          result_combine$Inverse_variance_weighted.Q_df <- trait1.trait2.dat.mr_heterogeneity$Q_df[trait1.trait2.dat.mr_heterogeneity$method == 'Inverse variance weighted']
          result_combine$Inverse_variance_weighted.Q_pval <- trait1.trait2.dat.mr_heterogeneity$Q_pval[trait1.trait2.dat.mr_heterogeneity$method == 'Inverse variance weighted']
        } else {
          #7.MR-EGGER SIMEX
          result_combine$isq = NA
          result_combine$isq <- as.numeric(result_combine$isq )
          result_combine$simex.beta <- NA
          result_combine$simex.beta <- as.numeric(result_combine$simex.beta)
          result_combine$simex.se <- NA
          result_combine$simex.se <- as.numeric(result_combine$simex.se )
          result_combine$simex.p <- NA
          result_combine$simex.p <- as.numeric(result_combine$simex.p)
          #8.HETERO
          trait1.trait2.dat.mr_heterogeneity = mr_heterogeneity(trait1.trait2.dat)
          result_combine$MR_Egger.Q <- NA
          result_combine$MR_Egger.Q <- as.numeric(result_combine$MR_Egger.Q)
          result_combine$MR_Egger.Q_df <- NA
          result_combine$MR_Egger.Q_df <- as.numeric(result_combine$MR_Egger.Q_df)
          result_combine$MR_Egger.Q_pval <- NA
          result_combine$MR_Egger.Q_pval <- as.numeric(result_combine$MR_Egger.Q_pval) 
          result_combine$Inverse_variance_weighted.Q <- trait1.trait2.dat.mr_heterogeneity$Q[trait1.trait2.dat.mr_heterogeneity$method == 'Inverse variance weighted']
          result_combine$Inverse_variance_weighted.Q_df <- trait1.trait2.dat.mr_heterogeneity$Q_df[trait1.trait2.dat.mr_heterogeneity$method == 'Inverse variance weighted']
          result_combine$Inverse_variance_weighted.Q_pval <- trait1.trait2.dat.mr_heterogeneity$Q_pval[trait1.trait2.dat.mr_heterogeneity$method == 'Inverse variance weighted']
          
        }
        #generate report and its path
        newpath <- paste0('AD_phewas/MR/save_report()/',i,'__ieu-b-2')
        dir.create(newpath)
        mr_report(trait1.trait2.dat,output_path = newpath)  
        
        
      }else{
        #5.turn the results into one row
        result_combine <- filter(trait1.trait2.results.withOR, method=='Wald ratio')
        result_MREGGER <- filter(trait1.trait2.results.withOR, method=='MR Egger')
        result_WMe <- filter(trait1.trait2.results.withOR, method=='Weighted median')
        result_WMo<- filter(trait1.trait2.results.withOR, method=='Weighted mode')
        result_SM <- filter(trait1.trait2.results.withOR, method=='Simple mode')
        result_combine <- left_join(result_combine,result_MREGGER,by=c("id.exposure","id.outcome","outcome","exposure"))
        result_combine <- left_join(result_combine,result_WMe,by=c("id.exposure","id.outcome","outcome","exposure"))
        result_combine <- left_join(result_combine,result_WMo,by=c("id.exposure","id.outcome","outcome","exposure"))
        result_combine <- left_join(result_combine,result_SM,by=c("id.exposure","id.outcome","outcome","exposure"))
        
        #6.MR-EGGER INTERCEPT
        result_combine$egger_intercept <- NA
        result_combine$egger_intercept <- as.numeric(result_combine$egger_intercept)
        result_combine$egger_intercept.pval <-  NA
        result_combine$egger_intercept.pval <- as.numeric(result_combine$egger_intercept.pval)
        
        #7.MR-EGGER SIMEX
        result_combine$isq = NA
        result_combine$isq <- as.numeric(result_combine$isq )
        result_combine$simex.beta <- NA
        result_combine$simex.beta <- as.numeric(result_combine$simex.beta)
        result_combine$simex.se <- NA
        result_combine$simex.se <- as.numeric(result_combine$simex.se )
        result_combine$simex.p <- NA
        result_combine$simex.p <- as.numeric(result_combine$simex.p)
        #8.HETERO
        result_combine$MR_Egger.Q <- NA
        result_combine$MR_Egger.Q <- as.numeric(result_combine$MR_Egger.Q)
        result_combine$MR_Egger.Q_df <- NA
        result_combine$MR_Egger.Q_df <- as.numeric(result_combine$MR_Egger.Q_df)
        result_combine$MR_Egger.Q_pval <- NA
        result_combine$MR_Egger.Q_pval <- as.numeric(result_combine$MR_Egger.Q_pval) 
        result_combine$Inverse_variance_weighted.Q <- NA
        result_combine$Inverse_variance_weighted.Q <- as.numeric(result_combine$Inverse_variance_weighted.Q)
        result_combine$Inverse_variance_weighted.Q_df <- NA
        result_combine$Inverse_variance_weighted.Q_df <- as.numeric(result_combine$Inverse_variance_weighted.Q_df)
        result_combine$Inverse_variance_weighted.Q_pval <- NA
        result_combine$Inverse_variance_weighted.Q_pval <- as.numeric(result_combine$Inverse_variance_weighted.Q_pval)
        
        #generate path but no report
        newpath <- paste0('/AD_phewas/MR/save_report()/',i,'__ieu-b-2/')
        dir.create(newpath)
        
        
      }
      
      #9.other statistics
      lor <- trait1.trait2.dat$beta.exposure
      af <- filter(plink.freq,SNP %in% trait1.trait2.dat$SNP)$MAF #SNP allele frequencey derived from 1kg plink bfile #plink.freq
      numbercase=	21982#kunkle el al 2019 GWAS
      numbercontrol=41944#kunkle el al 2019 GWAS
      ADprevalence=0.04
      
      trait1.trait2.mr_steiger = mr_steiger2(r_exp = get_r_from_pn(trait1.trait2.dat$pval.exposure,trait1.trait2.dat$samplesize.exposure), 
                                             r_out = get_r_from_lor(lor,af,numbercase,numbercontrol,ADprevalence), 
                                             n_exp = trait1.trait2.dat$samplesize.exposure, 
                                             n_out = trait1.trait2.dat$samplesize.outcome)  
      result_combine$steigertest_P <- trait1.trait2.mr_steiger$steiger_test
      result_combine$causal_dir <- trait1.trait2.mr_steiger$correct_causal_direction
      result_combine$steigertest_P.adj <- trait1.trait2.mr_steiger$steiger_test_adj
      result_combine$exp.R2 = trait1.trait2.mr_steiger$r2_exp
      exp.R2=trait1.trait2.mr_steiger$r2_exp
      result_combine$F.stat = (trait1.trait2.dat$samplesize.exposure[1] - dim(trait1.trait2.dat)[1] - 1) / (dim(trait1.trait2.dat)[1]) * exp.R2 / ( 1 - exp.R2 ) 
      
      #10.power calculate  

      ratio = 41944/ 21982  #kunkle el al 2019 GWAS
      n = 21982 + 41944     #kunkle el al 2019 GWAS
      OR = trait1.trait2.results.withOR$or[trait1.trait2.results.withOR$method == 'Inverse variance weighted'|trait1.trait2.results.withOR$method == 'Wald ratio']
      sig = 0.05
      rsq = exp.R2
      result_combine$power <-  pnorm(sqrt(n*rsq*(ratio/(1+ratio))*(1/(1+ratio)))*OR-qnorm(1-sig/2))
      
      write.csv(result_combine,paste0('/AD_phewas/MR/save_result_combine_individ/',i,'__ieu-b-2','.csv'),row.names = FALSE)
      
      #11.single_SNP analysis
      setwd(newpath)
      trait1.trait2.single_snp_analysis <- mr_singlesnp(trait1.trait2.dat)
      trait1.trait2.single_snp_analysis.withOR <- generate_odds_ratios(trait1.trait2.single_snp_analysis)
      write.csv(trait1.trait2.single_snp_analysis.withOR,paste0('SSA.',i,'__ieu-b-2','.csv'),row.names = FALSE)
      
      #12.leave-one-out analysis
      trait1.trait2.dat.mr_leaveoneout <- mr_leaveoneout(trait1.trait2.dat)
      trait1.trait2.dat.mr_leaveoneout.withOR <- generate_odds_ratios(trait1.trait2.dat.mr_leaveoneout)
      write.csv(trait1.trait2.dat.mr_leaveoneout.withOR ,paste0('LOO.',i,'__ieu-b-2','.csv'),row.names = FALSE)
      write.csv(result_combine_f,'/AD_phewas/MR/save_result_combine_individ/result_combine_run.csv',row.names=FALSE)
      
      #combine results
      result_combine_f <- bind_rows(result_combine_f,result_combine)
      write.csv(result_combine_f,'/AD_phewas/MR/save_result_combine_individ/result_combine_run.csv',row.names=FALSE)
    } else { #record the condition where no snp was found in outcome dataset
      reason.norun <- 'nosigsnp_in_outcome'
      df_norun_add <- data.frame(fieldid=i,
                                 reason.norun =reason.norun )
      df_norun <- rbind.data.frame(df_norun,df_norun_add)
      #output the record
      write.csv(df_norun,'/AD_phewas/MR/save_result_combine_individ/nosigsnp_ls.csv',row.names=FALSE)
      
    }
  } 
  else {#record the condition where no snp was found in exposure dataset
    reason.norun <- 'nosigsnp_in_exposure'
    df_norun_add <- data.frame(fieldid=i,
                               reason.norun=reason.norun )
    df_norun <- rbind.data.frame(df_norun,df_norun_add)
    #output the record
    write.csv(df_norun,'/AD_phewas/MR/save_result_combine_individ/nosigsnp_ls.csv',row.names=FALSE)
    
  }
}






