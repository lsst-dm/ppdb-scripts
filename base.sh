#!/usr/bin/env bash

check_var() {
  if [ $# -lt 1 ]; then
    echo "Usage: env_check VARIABLE_NAME [DEFAULT_VALUE]" >&2
    if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
      return 1
    else
      exit 1
    fi
  fi

  local var_name="$1"
  local default_value="${2:-}"

  if [ -z "${!var_name:-}" ]; then
    if [ -n "$default_value" ]; then
      printf -v "$var_name" '%s' "$default_value"
    else
      echo "Error: variable '$var_name' is unset or empty." >&2
      if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
        return 1
      else
        exit 1
      fi
    fi
  fi
}

export -f check_var
