#!/usr/bin/env python

import argparse
import sys
from pathlib import Path
from typing import IO

from felis import MetaDataBuilder, Schema
from sqlalchemy import MetaData
from sqlalchemy.schema import CreateTable
from sqlalchemy_bigquery import BigQueryDialect

PARTITIONS = {"DiaObject": "DATE(validityStart)"}

CLUSTERING = {
    "DiaObject": ["diaObjectId"],
    "DiaSource": ["diaObjectId"],
    "DiaForcedSource": ["diaObjectId"],
}


def sanitize_bq_comment(text: str) -> str:
    return text.replace("'", "")


def _generate_bq_ddl(
    metadata: MetaData, include_tables: set[str], project_id: str, dataset_name: str
) -> dict[str, str]:
    ddl_statements = {}

    for table_key, table in metadata.tables.items():
        raw_table_name = table_key.replace(f"{metadata.schema}.", "")
        if raw_table_name not in include_tables:
            print(f"Skipping table: {table_key} (not in include list)")
            continue

        print(f"Generating DDL for table: {raw_table_name}")

        compiled = str(CreateTable(table).compile(dialect=BigQueryDialect()))
        compiled = compiled.strip()

        # Remove trailing table-level OPTIONS clause if present
        # BigQuery syntax: ...\n) OPTIONS(description='...') — remove from \n) OPTIONS...
        if "\n) OPTIONS(" in compiled:
            compiled = compiled.split("\n) OPTIONS(")[0] + "\n)"

        elif compiled.endswith(")"):
            # If there's no OPTIONS but just ends with a paren, keep it
            pass
        else:
            raise ValueError("Unexpected DDL format")

        # Replace unqualified table name with fully-qualified
        schema_name, _ = table_key.split(".")
        fqtn = f"`{project_id}.{dataset_name}.{raw_table_name}`"
        compiled = compiled.replace(f"`{schema_name}`.`{raw_table_name}`", fqtn)
        compiled = compiled.replace("CREATE TABLE", "CREATE OR REPLACE TABLE")
        compiled = compiled.replace("DOUBLE", "FLOAT64")

        # Add additional clauses
        ddl_lines = [compiled]

        if raw_table_name in PARTITIONS:
            ddl_lines.append(f"PARTITION BY {PARTITIONS[raw_table_name]}")
        if raw_table_name in CLUSTERING:
            ddl_lines.append(f"CLUSTER BY {', '.join(CLUSTERING[raw_table_name])}")
        if table.comment:
            clean_comment = sanitize_bq_comment(table.comment)
            ddl_lines.append(f"OPTIONS(description='{clean_comment}')")

        ddl_statements[raw_table_name] = "\n".join(ddl_lines)

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
    parser.add_argument(
        "--schema-uri",
        type=str,
        default="resource://lsst.sdm.schemas/apdb.yaml",
        help="URI to the Felis schema file.",
    )
    return parser


def main():
    parser = _make_parser()
    args = parser.parse_args()

    # This will get the APDB schema from the sdm_schemas which is installed
    # in the Python environment.
    print(f"Loading APDB schema from: {args.schema_uri}")
    apdb_schema = Schema.from_uri(args.schema_uri)
    print(f"Loaded APDB schema version: {apdb_schema.version}")

    include_table = args.include_table or []
    include_table.extend(
        ["DiaObject", "DiaSource", "DiaForcedSource"]
    )  # These tables are always included.

    include_tables = set(include_table)

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
        print(f"DDL statements written to: {output_directory}")
    else:
        print("DDL statements:")
        _print_ddl(ddl_statements)


if __name__ == "__main__":
    main()
