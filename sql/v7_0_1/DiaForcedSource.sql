CREATE OR REPLACE TABLE `ppdb-dev-438721.ppdb_lsstcam.DiaForcedSource` (
	`diaForcedSourceId` INT64 NOT NULL OPTIONS(description='Unique id.'), 
	`diaObjectId` INT64 NOT NULL OPTIONS(description='Id of the DiaObject that this DiaForcedSource was associated with.'), 
	`ra` FLOAT64 NOT NULL OPTIONS(description='Right ascension coordinate of the position of the DiaObject at time radecMjdTai.'), 
	`dec` FLOAT64 NOT NULL OPTIONS(description='Declination coordinate of the position of the DiaObject at time radecMjdTai.'), 
	`visit` INT64 NOT NULL OPTIONS(description='Id of the visit where this forcedSource was measured.'), 
	`detector` INT64 NOT NULL OPTIONS(description='Id of the detector where this forcedSource was measured. Datatype short instead of byte because of DB concerns about unsigned bytes.'), 
	`psfFlux` FLOAT64 OPTIONS(description='Point Source model flux.'), 
	`psfFluxErr` FLOAT64 OPTIONS(description='Uncertainty of psfFlux.'), 
	`midpointMjdTai` FLOAT64 NOT NULL OPTIONS(description='Effective mid-visit time for this diaForcedSource, expressed as Modified Julian Date, International Atomic Time.'), 
	`scienceFlux` FLOAT64 OPTIONS(description='Forced photometry flux for a point source model measured on the visit image centered at the DiaObject position.'), 
	`scienceFluxErr` FLOAT64 OPTIONS(description='Uncertainty of scienceFlux.'), 
	`band` STRING(1) OPTIONS(description='Filter band this source was observed with.'), 
	`time_processed` TIMESTAMP NOT NULL OPTIONS(description='Time when this record was generated.'), 
	`time_withdrawn` TIMESTAMP OPTIONS(description='Time when this record was marked invalid.')
)
CLUSTER BY diaObjectId
OPTIONS(description='Forced-photometry source measurement on an individual difference Exposure for all objects in the DiaObject table.')