library(GwasDataImport)
library(readxl)

upload <- function(id, trait, units, EFO, download_dir)
{
	# Get file path
	# Each file has two datasets - one for the population estimate and one for the sibling estimate. Need to process the same file twice
	fn <- file.path(download_dir, paste0(id, ".summary.gz"))
	message(fn)
	message(file.exists(fn))

	# Get the sample size for sibs (n1) and population (n2) from the files
	n1 <- system(paste0("gunzip -c ", fn, " |  awk '{ print $9 }' | sort | tail -n 2 | head -n 1"), intern=T)
	n2 <- system(paste0("gunzip -c ", fn, " |  awk '{ print $13 }' | sort | tail -n 2 | head -n 1"), intern=T)
	message(n1)
	message(n2)

	# Do sibs dataset
	x <- Dataset$new(filename=fn)

	# Specify columns
	x$determine_columns(list(chr_col=2, snp_col=1, pos_col=3, oa_col=5, ea_col=4, beta_col=6, se_col=7, pval_col=8, ncontrol_col=9))

	# Input metadata
	x$collect_metadata(list(
		trait=trait, 
		ontology=EFO, 
		note='Sibling estimate', 
		unit=units, 
		build="HG19/GRCh37", 
		category="NA", 
		subcategory="NA", 
		group_name="public", 
		population="European", 
		sex="Males and Females", 
		author="Howe LJ", 
		year="2022", 
		consortium="Within family GWAS consortium", 
		sample_size=as.numeric(n1)))

	# Process dataset
	x$format_dataset()

	# Upload metadata
	x$api_metadata_upload()

	# Upload summary data
	x$api_gwasdata_upload()

	###

	# Do population dataset
	y <- Dataset$new(filename=fn)

	# Specify columns
	y$determine_columns(list(chr_col=2, snp_col=1, pos_col=3, oa_col=5, ea_col=4, beta_col=10, se_col=11, pval_col=12, ncontrol_col=13))
	# Process dataset
	y$format_dataset()

	# Input metadata
	y$collect_metadata(list(
		trait=trait, 
		ontology=EFO, 
		note='Population estimate', 
		unit=units, 
		build="HG19/GRCh37", 
		category="NA", 
		subcategory="NA", 
		group_name="public", 
		population="European", 
		sex="Males and Females", 
		author="Howe LJ", 
		year="2022", 
		consortium="Within family GWAS consortium", 
		sample_size=as.numeric(n2)))

	# Upload metadata
	y$api_metadata_upload()

	# Upload summary data
	y$api_gwasdata_upload()

	# Return the sib and population Dataset objects
	# We can use these to check status of each upload, get reports, release etc.
	return(list(x=x, y=y))
}

# Read in list of traits
traits <- readxl::read_xlsx("~/repo/opengwas-sibgwas-import/traits.xlsx")
traits$download_dir <- "/Volumes/MORPHY/Downloads/OneDrive_1_28-11-2021/"

# For each trait do the upload
res <- lapply(1:nrow(traits), function(i)
{
	do.call(upload, traits[i,])
})

# Check the qc status for each sib trait
sapply(res, function(i)
{
	i$x$api_qc_status() %>% fromJSON() %>% {.$results['status']}
})

# Check the qc status for each population trait
sapply(res, function(i)
{
	i$y$api_qc_status() %>% fromJSON() %>% {.$results['status']}
})

# Get the reports
lapply(res, function(i)
{
	i$x$api_report()
})

lapply(res, function(i)
{
	i$y$api_report()
})

# Release all datasets
lapply(res, function(i)
{
	i$x$api_gwas_release()
	i$y$api_gwas_release()
})

# Check the release status for each sib trait
sapply(res, function(i)
{
	i$x$api_qc_status() %>% fromJSON() %>% {.$results['status']}
})

# Check the release status for each population trait
sapply(res, function(i)
{
	i$y$api_qc_status() %>% fromJSON() %>% {.$results['status']}
})
