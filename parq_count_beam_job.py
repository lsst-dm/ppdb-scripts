import apache_beam as beam
from apache_beam.options.pipeline_options import (
    PipelineOptions,
    GoogleCloudOptions,
    SetupOptions,
)
from pyarrow import parquet
import pyarrow


class CustomOptions(PipelineOptions):
    @classmethod
    def _add_argparse_args(cls, parser):
        parser.add_argument("--input_path", required=True)


class CountParquetRows(beam.DoFn):
    def process(self, file_path):
        print(f"Reading: {file_path}")
        fs, path = pyarrow.fs.FileSystem.from_uri(file_path)
        table = parquet.read_table(path, filesystem=fs)
        yield f"{file_path}: {table.num_rows} rows"


def run(argv=None):
    options = PipelineOptions(argv)

    gcp_opts = options.view_as(GoogleCloudOptions)
    gcp_opts.project = "ppdb-dev-438721"
    gcp_opts.region = "us-central1"
    gcp_opts.job_name = "parquet-count-helloworld"
    gcp_opts.staging_location = "gs://rubin-ppdb-test-bucket-1/dataflow/staging"
    gcp_opts.temp_location = "gs://rubin-ppdb-test-bucket-1/dataflow/temp"

    options.view_as(SetupOptions).save_main_session = True

    custom_opts = options.view_as(CustomOptions)
    input_path = custom_opts.input_path

    with beam.Pipeline(options=options) as p:
        (
            p
            | "CreateFileList" >> beam.Create([input_path])
            | "CountRows" >> beam.ParDo(CountParquetRows())
            | "PrintResult" >> beam.Map(print)
        )


if __name__ == "__main__":
    run()
