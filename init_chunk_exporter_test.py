import logging
import os

from pathlib import Path

from lsst.dax.ppdb.export._chunk_exporter import ChunkExporter
from lsst.dax.ppdb.export import _chunk_exporter
from lsst.dax.ppdb.config import PpdbConfig

# logging.getLogger(_chunk_exporter.__name__).setLevel(logging.DEBUG)

os.environ["SDM_SCHEMAS_DIR"] = "../sdm_schemas"

cfg = PpdbConfig.from_uri("./ppdb_dm-49202.yaml")
ce = ChunkExporter(cfg, Path("./tmp"), batch_size=1000, compression_format="snappy")
