#!/usr/bin/env python

from felis import Schema, MetaDataBuilder

from sqlalchemy.schema import CreateTable
from sqlalchemy_bigquery import BigQueryDialect

import argparse
import sys
from pathlib import Path
from typing import IO


def _generate_bq_ddl(
    schema: Schema, project_id: str, dataset_name: str
) -> dict[str, str]:
    """Generate DDL from schema and write to file."""
    ddl_statements = {}
    for table_name, table in schema.tables.items():

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

        ddl += "PARTITION BY _PARTITIONTIME"  # Add partitioning clause

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
            print(f"DDL for {table_name} written to {output_file}")


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

    apdb_schema = Schema.from_uri("resource://lsst.sdm.schemas/apdb.yaml")
    print(f"Loaded APDB schema version: {apdb_schema.version}")

    metadata = MetaDataBuilder(apdb_schema, ignore_constraints=True).build()
    ddl_statements = _generate_bq_ddl(metadata, args.project_id, args.dataset_name)

    if args.include_table:
        # Filter the DDL statements based on the specified tables
        ddl_statements = {
            table_name: ddl
            for table_name, ddl in ddl_statements.items()
            if table_name in args.include_table
        }
        if not ddl_statements:
            print("No matching tables found.")
            sys.exit(1)

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
