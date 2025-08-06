#!/usr/bin/env python

import argparse
import sys
from pathlib import Path
from typing import IO

from felis import Schema, MetaDataBuilder

from sqlalchemy import MetaData
from sqlalchemy.schema import CreateTable
from sqlalchemy_bigquery import BigQueryDialect

PARTITIONS = {"DiaObject": "validityStart"}

CLUSTERING = {
    "DiaObject": ["diaObjectId"],
    "DiaSource": ["diaObjectId"],
    "DiaForcedSource": ["diaObjectId"],
}


def _generate_bq_ddl(
    metadata: MetaData, include_tables: list[str], project_id: str, dataset_name: str
) -> dict[str, str]:
    """Generate DDL from schema and write to file."""
    ddl_statements = {}
    for table_name, table in metadata.tables.items():

        if table_name.replace(f"{metadata.schema}.", "") not in include_tables:
            print(f"Skipping table: {table_name} (not in include list)")
            continue

        print(f"Generating DDL for table: {table_name}")

        # Compile the DDL statement
        ddl = str(CreateTable(table).compile(dialect=BigQueryDialect()))

        # Replace the table name with the fully qualified BigQuery table name
        schema_name, table_name = table_name.split(".")
        fully_qualified_table_name = f"`{project_id}.{dataset_name}.{table_name}`"
        ddl = ddl.replace(f"`{schema_name}`.`{table_name}`", fully_qualified_table_name)

        # Use CREATE OR REPLACE TABLE instead of CREATE TABLE
        ddl = ddl.replace("CREATE TABLE", "CREATE OR REPLACE TABLE")

        # Use BigQuery's FLOAT64 instead of DOUBLE
        ddl = ddl.replace("DOUBLE", "FLOAT64")

        partition_colname = "_PARTITIONTIME"
        if table_name in PARTITIONS:
            partition_colname = PARTITIONS[table_name]
        ddl += f"PARTITION BY {partition_colname}"  # Add partitioning clause

        if table_name in CLUSTERING:
            clustering_cols = CLUSTERING[table_name]
            ddl += f" CLUSTER BY {', '.join(clustering_cols)}"

        ddl_statements[table_name] = ddl
    return ddl_statements


def _print_ddl(ddl_statements, file: IO[str] = sys.stdout) -> None:
    """Print DDL statements to the console."""
    for table_name, ddl in ddl_statements.items():
        print(ddl, file=file)
        print("\n" + "-" * 80 + "\n", file=file)  # Add a separator between statements


def _write_ddl_to_directory(ddl_statements, output_directory: Path) -> None:
    """Write DDL statements to a file."""
    for table_name, ddl in ddl_statements.items():
        output_file = output_directory / f"{table_name}.sql"
        with open(output_file, "w") as f:
            f.write(ddl)
            print(f"Wrote DDL for '{table_name}' to: {output_file}")


def _make_parser():
    """Create an argument parser for command-line options."""
    parser = argparse.ArgumentParser(
        description="Generate BigQuery DDL from APDB Felis schema."
    )
    parser.add_argument(
        "--output-directory",
        type=str,
        required=False,
        help="Path to the output directory for DDL statements.",
    )
    parser.add_argument(
        "--project-id",
        type=str,
        required=True,
        help="GCP project ID.",
    )
    parser.add_argument(
        "--dataset-name",
        type=str,
        required=True,
        help="BigQuery dataset name.",
    )
    parser.add_argument(
        "--include-table",
        action="append",
        help="Specify tables to include. Can be used multiple times.",
    )
    return parser


def main():

    parser = _make_parser()
    args = parser.parse_args()

    # This will get the APDB schema from the sdm_schemas which is installed
    # in the Python environment.
    apdb_schema = Schema.from_uri("resource://lsst.sdm.schemas/apdb.yaml")
    print(f"Loaded APDB schema version: {apdb_schema.version}")

    include_tables = args.include_table or []
    if not include_tables:
        # Default to including specific tables if none specified
        include_tables = ["DiaObject", "DiaSource", "DiaForcedSource"]

    print(f"Including tables: {include_tables}")

    metadata = MetaDataBuilder(apdb_schema, ignore_constraints=True).build()
    ddl_statements = _generate_bq_ddl(
        metadata, include_tables, args.project_id, args.dataset_name
    )

    if not ddl_statements:
        print(
            "No DDL statements generated. Check if the specified tables exist in the schema."
        )
        return

    if args.output_directory:
        output_directory = Path(args.output_directory)
        if not output_directory.exists():
            output_directory.mkdir(parents=True, exist_ok=True)
        if not output_directory.is_dir():
            raise ValueError(f"Output path {output_directory} is not a directory.")
        _write_ddl_to_directory(ddl_statements, output_directory)
        print(f"DDL statements written to {output_directory}")
    else:
        print("DDL statements:")
        _print_ddl(ddl_statements)


if __name__ == "__main__":
    main()
