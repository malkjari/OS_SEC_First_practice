#!/bin/bash

# Функция для вывода справки
function show_help {
  echo "Usage: $0 [OPTIONS]"
  echo "Options:"
  echo "  -u, --users            Display a list of users and their home directories sorted alphabetically"
  echo "  -p, --processes        Display a list of running processes sorted by their IDs"
  echo "  -h, --help             Show this help message and exit"
  echo "  -l PATH, --log PATH    Redirect output to the specified file"
  echo "  -e PATH, --errors PATH Redirect errors to the specified file"
  exit 0
}

# Функция для вывода пользователей и их домашних директорий
function list_users {
  cut -d: -f1,6 /etc/passwd | sort
}

# Функция для вывода запущенных процессов
function list_processes {
  ps -e --sort=pid
}

# Переменные для хранения путей файлов для вывода и ошибок
LOG_PATH=""
ERROR_PATH=""

# Обработка аргументов командной строки
while getopts ":uphl:e:-:" opt; do
  case ${opt} in
    u )
      USERS_FLAG=true
      ;;
    p )
      PROCESSES_FLAG=true
      ;;
    h )
      HELP_FLAG=true
      ;;
    l )
      LOG_PATH="$OPTARG"
      ;;
    e )
      ERROR_PATH="$OPTARG"
      ;;
    - )
      case "${OPTARG}" in
        users )
          USERS_FLAG=true
          ;;
        processes )
          PROCESSES_FLAG=true
          ;;
        help )
          HELP_FLAG=true
          ;;
        log )
          LOG_PATH="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
          ;;
        errors )
          ERROR_PATH="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
          ;;
        * )
          echo "Invalid option: --${OPTARG}" >&2
          show_help
          ;;
      esac
      ;;
    \? )
      echo "Invalid option: -${OPTARG}" >&2
      show_help
      ;;
    : )
      echo "Option -${OPTARG} requires an argument." >&2
      show_help
      ;;
  esac
done
shift $((OPTIND -1))

# Если установлен флаг помощи, выводим справку и завершаем работу
if [ "$HELP_FLAG" = true ]; then
  show_help
fi

# Проверка доступности путей и настройка вывода
if [ -n "$LOG_PATH" ]; then
  if [ ! -w "$LOG_PATH" ] && [ ! -e "$LOG_PATH" ]; then
    echo "Log path is not writable or does not exist: $LOG_PATH" >&2
    exit 1
  fi
  exec 1>>"$LOG_PATH"
fi

if [ -n "$ERROR_PATH" ]; then
  if [ ! -w "$ERROR_PATH" ] && [ ! -e "$ERROR_PATH" ]; then
    echo "Error path is not writable or does not exist: $ERROR_PATH" >&2
    exit 1
  fi
  exec 2>>"$ERROR_PATH"
fi

# Выполнение действий в зависимости от установленных флагов
if [ "$USERS_FLAG" = true ]; then
  list_users
fi

if [ "$PROCESSES_FLAG" = true ]; then
  list_processes
fi

# Если не было установлено ни одного флага действий, выводим справку
if [ -z "$USERS_FLAG" ] && [ -z "$PROCESSES_FLAG" ]; then
  show_help
fi
