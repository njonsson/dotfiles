#!/usr/bin/env sh

set -u

usage() {
  usage_name=$(basename "$0")
  printf 'Usage: \e[1m%s \e[4mmode\e[22;24m\n' "${usage_name}" >&2
  printf '\n' >&2
  printf 'Examples:\n' >&2
  printf '\n' >&2
  printf '  # \e[1m%s 664\e[22m\n' "${usage_name}" >&2
  printf '  %s\n' "$($0 664)" >&2
  printf '\n' >&2
  printf '  # \e[1m%s | %s\e[22m\n' "printf '755\\nu=rw\\n'" "${usage_name}" >&2
  printf '  %s\n' "$($0 755)" >&2
  printf '  %s\n' "$($0 u=rw)" >&2
}

invalid_mode() {
  printf "%s: unsupported mode '%s'\n" "$(basename "$0")" "$1" >&2
}

digit_to_permissions() {
  case "$1" in
    0)
      printf '%s' '-'
      ;;
    1)
      printf '%s' 'x'
      ;;
    2)
      printf '%s' 'w'
      ;;
    3)
      printf '%s' 'wx'
      ;;
    4)
      printf '%s' 'r'
      ;;
    5)
      printf '%s' 'rx'
      ;;
    6)
      printf '%s' 'rw'
      ;;
    7)
      printf '%s' 'rwx'
      ;;
    *)
      return 1
      ;;
  esac
}

absolute_to_symbolic() {
  abs_mode=$1

  abs_user=${abs_mode%??}
  abs_tail=${abs_mode#?}
  abs_group=${abs_tail%?}
  abs_other=${abs_mode##??}

  if abs_user_perms=$(digit_to_permissions "${abs_user}"); then
    :
  else
    return 1
  fi

  if abs_group_perms=$(digit_to_permissions "${abs_group}"); then
    :
  else
    return 1
  fi

  if abs_other_perms=$(digit_to_permissions "${abs_other}"); then
    :
  else
    return 1
  fi

  abs_result=''
  abs_prev_classes=''
  abs_prev_perms=''

  for abs_class in u g o; do
    case ${abs_class} in
      u)
        abs_perms=${abs_user_perms}
        ;;
      g)
        abs_perms=${abs_group_perms}
        ;;
      o)
        abs_perms=${abs_other_perms}
        ;;
    *)
      return 1
      ;;
    esac

    if [ -z "${abs_prev_classes}" ]; then
      abs_prev_classes=${abs_class}
      abs_prev_perms=${abs_perms}
    elif [ "${abs_perms}" = "${abs_prev_perms}" ]; then
      abs_prev_classes=${abs_prev_classes}${abs_class}
    else
      if [ -z "${abs_result}" ]; then
        abs_result=${abs_prev_classes}=${abs_prev_perms}
      else
        abs_result=${abs_result},${abs_prev_classes}=${abs_prev_perms}
      fi
      abs_prev_classes=${abs_class}
      abs_prev_perms=${abs_perms}
    fi
  done

  if [ -z "${abs_result}" ]; then
    abs_result=${abs_prev_classes}=${abs_prev_perms}
  else
    abs_result=${abs_result},${abs_prev_classes}=${abs_prev_perms}
  fi

  printf '%s\n' "${abs_result}"
}

permissions_to_digit() {
  perms_value=$1

  case ${perms_value} in
    ''|-)
      printf '%s' '0'
      return 0
      ;;
    *)
      ;;
  esac

  case ${perms_value} in
    *[!rwx]*)
      return 1
      ;;
    *)
      ;;
  esac

  perms_bits=0

  case ${perms_value} in
    *r*)
      perms_bits=$((perms_bits | 4))
      ;;
    *)
      ;;
  esac
  case ${perms_value} in
    *w*)
      perms_bits=$((perms_bits | 2))
      ;;
    *)
      ;;
  esac
  case ${perms_value} in
    *x*)
      perms_bits=$((perms_bits | 1))
      ;;
    *)
      ;;
  esac

  printf '%d' "${perms_bits}"
}

symbolic_to_absolute() {
  sym_spec=$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')

  sym_u=0
  sym_g=0
  sym_o=0
  sym_seen_component=no

  sym_saved_ifs=${IFS}
  IFS=,
  for sym_component in ${sym_spec}; do
    sym_seen_component=yes

    case ${sym_component} in
      *=*)
        sym_classes=${sym_component%%=*}
        sym_perms=${sym_component#*=}
        ;;
      *)
        IFS=${sym_saved_ifs}
        return 1
        ;;
    esac

    if [ -z "${sym_classes}" ]; then
      IFS=${sym_saved_ifs}
      return 1
    fi

    case ${sym_classes} in
      *[!ugo]*)
        IFS=${sym_saved_ifs}
        return 1
        ;;
      *)
        ;;
    esac

    if sym_bits=$(permissions_to_digit "${sym_perms}"); then
      :
    else
      IFS=${sym_saved_ifs}
      return 1
    fi

    case ${sym_classes} in
      *u*)
        sym_u=${sym_bits}
        ;;
      *)
        ;;
    esac
    case ${sym_classes} in
      *g*)
        sym_g=${sym_bits}
        ;;
      *)
        ;;
    esac
    case ${sym_classes} in
      *o*)
        sym_o=${sym_bits}
        ;;
      *)
        ;;
    esac
  done
  IFS=${sym_saved_ifs}

  if [ "${sym_seen_component}" = no ]; then
    return 1
  fi

  printf '%01d%01d%01d\n' "${sym_u}" "${sym_g}" "${sym_o}"
}

process_token() {
  process_value=$1

  if [ -z "${process_value}" ]; then
    printf '\n'
    return 0
  fi

  case ${process_value} in
    [0-7][0-7][0-7])
      if absolute_to_symbolic "${process_value}"; then
        :
      else
        invalid_mode "${process_value}"
        return 1
      fi
      ;;
    *)
      if symbolic_to_absolute "${process_value}"; then
        :
      else
        invalid_mode "${process_value}"
        return 1
      fi
      ;;
  esac
}

process_stdin() {
  process_status=0
  while IFS= read -r process_line; do
    if process_token "${process_line}"; then
      :
    else
      process_status=1
    fi
  done
  return "${process_status}"
}

main() {
  if [ -p /dev/stdin ]; then
    if [ $# -eq 0 ]; then
      process_stdin
      exit $?
    fi
  fi

  if [ $# -eq 1 ]; then
    process_token "$1"
    exit $?
  fi

  usage
  exit 1
}

main "$@"
