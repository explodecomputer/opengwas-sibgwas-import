library(GwasDataImport)
library(readxl)

upload <- function(id, trait, units, EFO, download_dir)
{
	fn <- file.path(download_dir, paste0(id, ".summary.gz"))
	message(fn)
	message(file.exists(fn))
	n1 <- system(paste0("gunzip -c ", fn, " |  awk '{ print $9 }' | sort | tail -n 2 | head -n 1"), intern=T)
	n2 <- system(paste0("gunzip -c ", fn, " |  awk '{ print $13 }' | sort | tail -n 2 | head -n 1"), intern=T)
	message(n1)
	message(n2)

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

	# Initialise
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

	return(list(x=x, y=y))
}


traits <- readxl::read_xlsx("~/repo/opengwas-sibgwas-import/traits.xlsx")
traits$download_dir <- "/Volumes/MORPHY/Downloads/OneDrive_1_28-11-2021/"

res <- lapply(1:nrow(traits), function(i)
{
	do.call(upload, traits[i,])
})
