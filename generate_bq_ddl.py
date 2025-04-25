#!/usr/bin/env python

from felis import Schema, MetaDataBuilder

from sqlalchemy.schema import CreateTable
from sqlalchemy_bigquery import BigQueryDialect

import argparse
import sys
from pathlib import Path
from typing import IO


def _generate_bq_ddl(schema: Schema, project_id: str, dataset_name: str) -> list[str]:
    """Generate DDL from schema and write to file."""
    ddl_statements = []
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

        ddl_statements.append(ddl)
    return ddl_statements


def _print_ddl(ddl_statements, file: IO[str] = sys.stdout) -> None:
    """Print DDL statements to the console."""
    for ddl in ddl_statements:
        print(ddl, file=file)
        print("\n" + "-" * 80 + "\n", file=file)  # Add a separator between statements


def _write_ddl_to_file(ddl_statements, output_file: Path) -> None:
    """Write DDL statements to a file."""
    with open(output_file, "w") as f:
        _print_ddl(ddl_statements, file=f)


def _make_parser():
    """Create an argument parser for command-line options."""
    parser = argparse.ArgumentParser(
        description="Generate BigQuery DDL from APDB Felis schema."
    )
    parser.add_argument(
        "--output-file",
        type=str,
        required=False,
        default=None,
        help="Path to the output file for DDL statements.",
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
    return parser


def main():

    parser = _make_parser()
    args = parser.parse_args()

    apdb_schema = Schema.from_uri("resource://lsst.sdm.schemas/apdb.yaml")
    print(f"Loaded APDB schema version: {apdb_schema.version}")

    metadata = MetaDataBuilder(apdb_schema, ignore_constraints=True).build()
    ddl_statements = _generate_bq_ddl(metadata, args.project_id, args.dataset_name)

    if args.output_file:
        output_file = Path(args.output_file)
        if output_file.parent and not output_file.parent.exists():
            output_file.parent.mkdir(parents=True, exist_ok=True)
        _write_ddl_to_file(ddl_statements, output_file)
        print(f"DDL statements written to {output_file}")
    else:
        print("DDL statements:")
        _print_ddl(ddl_statements)


if __name__ == "__main__":
    main()
