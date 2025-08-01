#!/bin/sh
# shellcheck shell=sh
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
##@Version           :  202502011400-git
# @@Author           :  Jason Hempstead
# @@Contact          :  jason@casjaysdev.pro
# @@License          :  WTFPL
# @@ReadME           :  install.sh --help
# @@Copyright        :  Copyright: (c) 2025 Jason Hempstead, Casjays Developments
# @@Created          :  Saturday, Feb 01, 2025 14:00 EST
# @@File             :  install.sh
# @@Description      :  Enterprise Jitsi Meet + Keycloak automated installer with monitoring stack
# @@Changelog        :  Initial release with complete enterprise feature set
# @@TODO             :  Add support for additional Linux distributions and cloud providers
# @@Other            :  Supports curl | sh installation method
# @@Resource         :  https://github.com/gistmgr/jitsi
# @@Terminal App     :  yes
# @@sudo/root        :  yes
# @@Template         :  bash/installer
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# shellcheck disable=SC1003,SC2016,SC2031,SC2120,SC2155,SC2199,SC2317
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
APPNAME="install.sh"
VERSION="202502011400-git"
USER="${SUDO_USER:-$USER}"
RUN_USER="${RUN_USER:-$USER}"
USER_HOME="${USER_HOME:-$HOME}"
SCRIPT_SRC_DIR=`dirname "$0"`
JITSI_INSTALLER_REQUIRE_SUDO="${JITSI_INSTALLER_REQUIRE_SUDO:-yes}"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Section 2: Global Variables and Configuration
JITSI_PROJECT_NAME="jitsi"
JITSI_BASE_DIR="/opt/jitsi"
JITSI_ROOTFS_DIR="$JITSI_BASE_DIR/rootfs"
JITSI_ENV_FILE="$JITSI_BASE_DIR/.env"
JITSI_SCRIPT_LOG_DIR="/var/log/casjaysdev/jitsi"
JITSI_SCRIPT_LOG_FILE="$JITSI_SCRIPT_LOG_DIR/setup.log"
JITSI_TEMP_DIR="/tmp/jitsi-install-$$"
JITSI_CRON_FILE="/etc/cron.d/jitsi"
JITSI_CRON_LOG_DIR="/var/log/casjaysdev/jitsi/cron"

JITSI_LETSENCRYPT_CERT_DIR="/etc/letsencrypt/live/domain"
JITSI_SSL_CERT_PATH="$JITSI_LETSENCRYPT_CERT_DIR/fullchain.pem"
JITSI_SSL_KEY_PATH="$JITSI_LETSENCRYPT_CERT_DIR/privkey.pem"

JITSI_DOCKER_NETWORK_NAME="jitsi"
JITSI_DOCKER_BRIDGE_IP=""
JITSI_DOCKER_LOG_DRIVER="json-file"
JITSI_DOCKER_LOG_MAX_SIZE="10m"
JITSI_DOCKER_LOG_MAX_FILES="1"

JITSI_DEFAULT_ORG_NAME="CasjaysDev MEET"
JITSI_ORG_NAME="${JITSI_ORG_NAME:-$JITSI_DEFAULT_ORG_NAME}"
JITSI_DEFAULT_TIMEZONE="America/New_York"
JITSI_DEFAULT_ADMIN_USERNAME="administrator"
JITSI_ROOM_CLEANUP_INTERVAL="604800"
JITSI_ANONYMOUS_RATE_LIMIT="5"
JITSI_AUTHENTICATED_RATE_LIMIT="20"

JITSI_USE_HOST_MAILSERVER="true"
JITSI_HOST_MAILSERVER_IP="172.17.0.1"
JITSI_HOST_MAILSERVER_PORTS="25,465"
JITSI_SMTP_HOST="172.17.0.1"
JITSI_SMTP_PORT="25"
JITSI_SMTP_AUTH="false"
JITSI_SMTP_TLS="false"
JITSI_SMTP_FROM_NAME="$JITSI_ORG_NAME"

JITSI_NETWORK_TIMEOUT="10"
JITSI_HEALTH_CHECK_TIMEOUT="30"
JITSI_INSTALL_TIMEOUT="600"
JITSI_DOCKER_TIMEOUT="300"
JITSI_SERVICE_STARTUP_TIMEOUT="300"
JITSI_MIN_MEMORY_MB="2048"
JITSI_MIN_DISK_GB="10"
JITSI_MIN_CPU_CORES="2"

JITSI_EXIT_SUCCESS=0
JITSI_EXIT_ERROR=1
JITSI_EXIT_USAGE=2
JITSI_EXIT_PREREQ=3
JITSI_EXIT_NETWORK=4
JITSI_EXIT_PERMISSION=5

JITSI_RAW_OUTPUT="false"
JITSI_QUIET_MODE="false"
JITSI_VERBOSE_MODE="false"
JITSI_DEBUG_MODE="false"

# Section 3: Color System and Visual Elements
__init_colors() {
  if [ -t 1 ] && [ "$JITSI_RAW_OUTPUT" = "false" ]; then
    # Dracula-inspired color palette (POSIX-compliant)
    # Background: #282a36, Foreground: #f8f8f2
    # Colors based on Dracula theme
    JITSI_RED=`printf '\033[38;5;203m'`        # #ff5555 - Dracula red
    JITSI_GREEN=`printf '\033[38;5;84m'`       # #50fa7b - Dracula green
    JITSI_YELLOW=`printf '\033[38;5;228m'`     # #f1fa8c - Dracula yellow
    JITSI_BLUE=`printf '\033[38;5;117m'`       # #8be9fd - Dracula cyan
    JITSI_PURPLE=`printf '\033[38;5;141m'`     # #bd93f9 - Dracula purple
    JITSI_CYAN=`printf '\033[38;5;159m'`       # #8be9fd - Dracula cyan variant
    JITSI_PINK=`printf '\033[38;5;212m'`       # #ff79c6 - Dracula pink
    JITSI_ORANGE=`printf '\033[38;5;215m'`     # #ffb86c - Dracula orange
    JITSI_WHITE=`printf '\033[38;5;253m'`      # #f8f8f2 - Dracula foreground
    JITSI_GRAY=`printf '\033[38;5;248m'`       # #6272a4 - Dracula comment
    JITSI_BOLD=`printf '\033[1m'`
    JITSI_DIM=`printf '\033[2m'`
    JITSI_ITALIC=`printf '\033[3m'`
    JITSI_UNDERLINE=`printf '\033[4m'`
    JITSI_NC=`printf '\033[0m'`
    
    # Bright colors
    JITSI_BRIGHT_RED=`printf '\033[1;38;5;203m'`
    JITSI_BRIGHT_GREEN=`printf '\033[1;38;5;84m'`
    JITSI_BRIGHT_YELLOW=`printf '\033[1;38;5;228m'`
    JITSI_BRIGHT_BLUE=`printf '\033[1;38;5;117m'`
    JITSI_BRIGHT_PURPLE=`printf '\033[1;38;5;141m'`
    JITSI_BRIGHT_CYAN=`printf '\033[1;38;5;159m'`
    JITSI_BRIGHT_PINK=`printf '\033[1;38;5;212m'`
    
    # Background colors
    JITSI_BG_GREEN=`printf '\033[48;5;84m\033[38;5;232m'`
    JITSI_BG_RED=`printf '\033[48;5;203m\033[38;5;232m'`
    JITSI_BG_BLUE=`printf '\033[48;5;117m\033[38;5;232m'`
    JITSI_BG_PURPLE=`printf '\033[48;5;141m\033[38;5;232m'`
    JITSI_BG_DARK=`printf '\033[48;5;236m'`
    
    # Visual symbols
    JITSI_CHECKMARK="✓"
    JITSI_CROSSMARK="✗"
    JITSI_ARROW="→"
    JITSI_BULLET="•"
    JITSI_GEAR="⚙"
    JITSI_ROCKET="🚀"
    JITSI_LOCK="🔒"
    JITSI_GLOBE="🌍"
    JITSI_DOCKER="🐳"
    
    # Prefixes with colors and emojis
    INFO_PREFIX="${JITSI_BLUE}ℹ${JITSI_NC} "
    SUCCESS_PREFIX="${JITSI_GREEN}${JITSI_CHECKMARK}${JITSI_NC} "
    WARNING_PREFIX="${JITSI_YELLOW}⚠${JITSI_NC} "
    ERROR_PREFIX="${JITSI_RED}${JITSI_CROSSMARK}${JITSI_NC} "
    INPUT_PREFIX="${JITSI_PURPLE}❯${JITSI_NC} "
    PROGRESS_PREFIX="${JITSI_CYAN}${JITSI_GEAR}${JITSI_NC} "
    SECURITY_PREFIX="${JITSI_PURPLE}${JITSI_LOCK}${JITSI_NC} "
    NETWORK_PREFIX="${JITSI_CYAN}${JITSI_GLOBE}${JITSI_NC} "
    DOCKER_PREFIX="${JITSI_BLUE}${JITSI_DOCKER}${JITSI_NC} "
  else
    # Plain text equivalents for raw mode
    JITSI_RED=""
    JITSI_GREEN=""
    JITSI_YELLOW=""
    JITSI_BLUE=""
    JITSI_PURPLE=""
    JITSI_CYAN=""
    JITSI_WHITE=""
    JITSI_BOLD=""
    JITSI_DIM=""
    JITSI_NC=""
    
    JITSI_BRIGHT_RED=""
    JITSI_BRIGHT_GREEN=""
    JITSI_BRIGHT_YELLOW=""
    JITSI_BRIGHT_BLUE=""
    JITSI_BRIGHT_PURPLE=""
    JITSI_BRIGHT_CYAN=""
    
    JITSI_BG_GREEN=""
    JITSI_BG_RED=""
    JITSI_BG_BLUE=""
    
    JITSI_CHECKMARK="[OK]"
    JITSI_CROSSMARK="[FAIL]"
    JITSI_ARROW="->"
    JITSI_BULLET="*"
    JITSI_GEAR="[WORK]"
    JITSI_ROCKET="[START]"
    JITSI_LOCK="[SECURE]"
    JITSI_GLOBE="[NET]"
    JITSI_DOCKER="[DOCKER]"
    
    INFO_PREFIX="[INFO] "
    SUCCESS_PREFIX="[SUCCESS] "
    WARNING_PREFIX="[WARNING] "
    ERROR_PREFIX="[ERROR] "
    INPUT_PREFIX="[INPUT] "
    PROGRESS_PREFIX="[PROGRESS] "
    SECURITY_PREFIX="[SECURITY] "
    NETWORK_PREFIX="[NETWORK] "
    DOCKER_PREFIX="[DOCKER] "
  fi
}

# Section 4: Dual Logging System Functions
__log_message() {
  JITSI_LOG_LEVEL="$1"
  JITSI_LOG_MESSAGE="$2"
  JITSI_LOG_TIMESTAMP=`date '+%Y-%m-%d %H:%M:%S'`
  
  # Ensure log directory exists
  if [ ! -d "$JITSI_SCRIPT_LOG_DIR" ]; then
    mkdir -p "$JITSI_SCRIPT_LOG_DIR" 2>/dev/null || true
  fi
  
  # Log to file without colors
  printf "[%s] [%s] %s\n" "$JITSI_LOG_TIMESTAMP" "$JITSI_LOG_LEVEL" "$JITSI_LOG_MESSAGE" >> "$JITSI_SCRIPT_LOG_FILE" 2>/dev/null || true
}

# Printf helper functions for consistent color output
printf_newline_color() {
  # Usage: printf_newline_color COLOR "format string" args...
  local color="$1"
  shift
  local format="$1"
  shift
  printf "${color}${format}${JITSI_NC}\n" "$@"
}

printf_newline_nc() {
  # Usage: printf_newline_nc "format string" args...
  local format="$1"
  shift
  printf "${format}\n" "$@"
}

printf_reset_color() {
  # Usage: printf_reset_color COLOR "format string" args...
  local color="$1"
  shift
  local format="$1"
  shift
  printf "${color}${format}${JITSI_NC}" "$@"
}

printf_reset_nc() {
  # Usage: printf_reset_nc "format string" args...
  local format="$1"
  shift
  printf "${format}" "$@"
}

printf_log() {
  # Usage: printf_log LEVEL PREFIX "message"
  local level="$1"
  local prefix="$2"
  local message="$3"
  printf "%s%s\n" "$prefix" "$message"
  __log_message "$level" "$message"
}

__info() {
  printf_log "INFO" "$INFO_PREFIX" "$1"
}

__success() {
  printf_log "SUCCESS" "$SUCCESS_PREFIX" "$1"
}

__warning() {
  printf_newline_color "$JITSI_YELLOW" "%s%s" "$WARNING_PREFIX" "$1"
  __log_message "WARNING" "$1"
}

__error() {
  printf_newline_color "$JITSI_RED" "%s%s" "$ERROR_PREFIX" "$1" >&2
  __log_message "ERROR" "$1"
}

__progress() {
  printf_log "PROGRESS" "$PROGRESS_PREFIX" "$1"
}

__input() {
  # Usage: __input "prompt message" [default_value]
  local prompt="$1"
  local default="$2"
  
  printf_reset_color "$JITSI_PURPLE" "\n%s%s" "$INPUT_PREFIX" "$prompt"
  printf_newline_nc ""
  
  if [ -n "$default" ]; then
    printf_newline_nc "Press Enter to use default: %s" "$default"
  fi
  
  printf_reset_nc "%s " "$prompt:"
}

# Spinner function for long-running operations
__spinner() {
  # Usage: __spinner "message" "command"
  JITSI_SPINNER_MSG="$1"
  JITSI_SPINNER_CMD="$2"
  JITSI_SPINNER_PID=""
  JITSI_SPINNER_CHARS="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
  JITSI_SPINNER_DELAY="0.1"
  
  # Start spinner in background
  (
    i=0
    while true; do
      char=`printf "%s" "$JITSI_SPINNER_CHARS" | cut -c$((i+1))`
      printf "\r${PROGRESS_PREFIX}%s %s  " "$JITSI_SPINNER_MSG" "$char"
      sleep "$JITSI_SPINNER_DELAY"
      i=$(((i+1) % 10))
    done
  ) &
  JITSI_SPINNER_PID=$!
  
  # Execute command
  eval "$JITSI_SPINNER_CMD" >/tmp/jitsi-spinner-output.$$ 2>&1
  JITSI_SPINNER_RC=$?
  
  # Stop spinner
  kill $JITSI_SPINNER_PID 2>/dev/null
  wait $JITSI_SPINNER_PID 2>/dev/null
  
  # Clear spinner line
  printf "\r%40s\r" " "
  
  # Show result
  if [ $JITSI_SPINNER_RC -eq 0 ]; then
    __success "$JITSI_SPINNER_MSG"
  else
    __error "$JITSI_SPINNER_MSG failed"
    if [ -f /tmp/jitsi-spinner-output.$$ ]; then
      cat /tmp/jitsi-spinner-output.$$
    fi
  fi
  
  # Cleanup
  rm -f /tmp/jitsi-spinner-output.$$
  
  return $JITSI_SPINNER_RC
}

__header() {
  JITSI_HEADER_TEXT="$1"
  JITSI_HEADER_LENGTH=`printf "%s" "$JITSI_HEADER_TEXT" | wc -c`
  JITSI_HEADER_PADDING=`expr 60 - $JITSI_HEADER_LENGTH`
  JITSI_HEADER_PADDING=`expr $JITSI_HEADER_PADDING / 2`
  
  # Ensure padding is never negative
  if [ $JITSI_HEADER_PADDING -lt 0 ]; then
    JITSI_HEADER_PADDING=0
  fi
  
  printf "\n"
  printf_reset_color "${JITSI_BOLD}${JITSI_BLUE}" "═%.0s" `seq 1 60`
  printf "\n"
  
  printf_reset_color "${JITSI_BOLD}${JITSI_BLUE}" "║"
  printf "%*s" $JITSI_HEADER_PADDING ""
  printf_reset_color "${JITSI_BOLD}${JITSI_WHITE}" "%s" "$JITSI_HEADER_TEXT"
  printf "%*s" $JITSI_HEADER_PADDING ""
  printf_newline_color "${JITSI_BOLD}${JITSI_BLUE}" "║"
  
  printf_reset_color "${JITSI_BOLD}${JITSI_BLUE}" "═%.0s" `seq 1 60`
  printf "\n\n"
}

__banner() {
  if [ "$JITSI_RAW_OUTPUT" = "false" ]; then
    printf "\n"
    printf_newline_color "${JITSI_BOLD}${JITSI_BLUE}" "     ██╗██╗████████╗███████╗██╗    ███╗   ███╗███████╗███████╗████████╗"
    printf_newline_color "${JITSI_BOLD}${JITSI_BLUE}" "     ██║██║╚══██╔══╝██╔════╝██║    ████╗ ████║██╔════╝██╔════╝╚══██╔══╝"
    printf_newline_color "${JITSI_BOLD}${JITSI_BLUE}" "     ██║██║   ██║   ███████╗██║    ██╔████╔██║█████╗  █████╗     ██║   "
    printf_newline_color "${JITSI_BOLD}${JITSI_BLUE}" "██   ██║██║   ██║   ╚════██║██║    ██║╚██╔╝██║██╔══╝  ██╔══╝     ██║   "
    printf_newline_color "${JITSI_BOLD}${JITSI_BLUE}" "╚█████╔╝██║   ██║   ███████║██║    ██║ ╚═╝ ██║███████╗███████╗   ██║   "
    printf_newline_color "${JITSI_BOLD}${JITSI_BLUE}" " ╚════╝ ╚═╝   ╚═╝   ╚══════╝╚═╝    ╚═╝     ╚═╝╚══════╝╚══════╝   ╚═╝   "
    printf_newline_color "${JITSI_BOLD}${JITSI_WHITE}" "\nEnterprise Installation System"
    printf_newline_color "${JITSI_DIM}" "Version: %s\n" "$VERSION"
  else
    printf "\n=== JITSI MEET ENTERPRISE INSTALLATION ===\n"
    printf "Version: %s\n\n" "$VERSION"
  fi
}

__spinner() {
  JITSI_SPINNER_PID="$1"
  JITSI_SPINNER_MSG="$2"
  JITSI_SPINNER_COUNT=0
  
  if [ "$JITSI_RAW_OUTPUT" = "true" ] || [ "$JITSI_QUIET_MODE" = "true" ]; then
    printf "%s... " "$JITSI_SPINNER_MSG"
    wait "$JITSI_SPINNER_PID" 2>/dev/null
    printf "done\n"
    return
  fi
  
  printf "%s " "$JITSI_SPINNER_MSG"
  
  while kill -0 "$JITSI_SPINNER_PID" 2>/dev/null; do
    case `expr $JITSI_SPINNER_COUNT % 10` in
      0) printf "\b\b\b   \b\b\b⠋" ;;
      1) printf "\b⠙" ;;
      2) printf "\b⠹" ;;
      3) printf "\b⠸" ;;
      4) printf "\b⠼" ;;
      5) printf "\b⠴" ;;
      6) printf "\b⠦" ;;
      7) printf "\b⠧" ;;
      8) printf "\b⠇" ;;
      9) printf "\b⠏" ;;
    esac
    JITSI_SPINNER_COUNT=`expr $JITSI_SPINNER_COUNT + 1`
    sleep 0.1
  done
  
  printf "\b ${JITSI_GREEN}${JITSI_CHECKMARK}${JITSI_NC}\n"
}

# Section 5: System Detection and Validation Functions
__detect_distribution() {
  if [ ! -f /etc/os-release ]; then
    __error "Cannot detect operating system. /etc/os-release not found."
    exit $JITSI_EXIT_PREREQ
  fi
  
  JITSI_OS_ID=`grep '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"'`
  JITSI_OS_VERSION=`grep '^VERSION_ID=' /etc/os-release | cut -d= -f2 | tr -d '"'`
  
  case "$JITSI_OS_ID" in
    debian)
      case "$JITSI_OS_VERSION" in
        10|11|12|13)
          JITSI_DISTRO_FAMILY="debian"
          JITSI_PKG_MANAGER="apt"
          __info "Detected Debian $JITSI_OS_VERSION"
          ;;
        *)
          __error "Debian $JITSI_OS_VERSION is not supported"
          __error "Supported versions: 10, 11, 12, 13"
          exit $JITSI_EXIT_PREREQ
          ;;
      esac
      ;;
    ubuntu)
      case "$JITSI_OS_VERSION" in
        18.04|20.04|22.04|24.04)
          JITSI_DISTRO_FAMILY="debian"
          JITSI_PKG_MANAGER="apt"
          __info "Detected Ubuntu $JITSI_OS_VERSION"
          ;;
        *)
          __error "Ubuntu $JITSI_OS_VERSION is not supported"
          __error "Supported versions: 18.04, 20.04, 22.04, 24.04"
          exit $JITSI_EXIT_PREREQ
          ;;
      esac
      ;;
    rhel|centos|rocky|almalinux)
      case "$JITSI_OS_VERSION" in
        8*|9*)
          JITSI_DISTRO_FAMILY="rhel"
          JITSI_PKG_MANAGER="dnf"
          __info "Detected $JITSI_OS_ID $JITSI_OS_VERSION"
          ;;
        *)
          __error "$JITSI_OS_ID $JITSI_OS_VERSION is not supported"
          __error "Supported versions: 8.x, 9.x"
          exit $JITSI_EXIT_PREREQ
          ;;
      esac
      ;;
    fedora)
      case "$JITSI_OS_VERSION" in
        37|38|39|40)
          JITSI_DISTRO_FAMILY="rhel"
          JITSI_PKG_MANAGER="dnf"
          __info "Detected Fedora $JITSI_OS_VERSION"
          ;;
        *)
          __error "Fedora $JITSI_OS_VERSION is not supported"
          __error "Supported versions: 37, 38, 39, 40"
          exit $JITSI_EXIT_PREREQ
          ;;
      esac
      ;;
    *)
      __error "Operating system '$JITSI_OS_ID' is not supported"
      __error "Supported distributions:"
      __error "  - Debian 10, 11, 12, 13"
      __error "  - Ubuntu 18.04, 20.04, 22.04, 24.04"
      __error "  - RHEL/CentOS/Rocky/AlmaLinux 8.x, 9.x"
      __error "  - Fedora 37, 38, 39, 40"
      exit $JITSI_EXIT_PREREQ
      ;;
  esac
}

__validate_system_resources() {
  __header "System Resource Validation"
  
  # Get total memory in MB
  JITSI_TOTAL_MEMORY_KB=`grep MemTotal /proc/meminfo | awk '{print $2}'`
  JITSI_TOTAL_MEMORY_MB=`expr $JITSI_TOTAL_MEMORY_KB / 1024`
  
  # Get CPU cores
  JITSI_CPU_CORES=`nproc`
  
  # Get available disk space in GB
  JITSI_AVAILABLE_DISK_KB=`df -k "$JITSI_BASE_DIR" 2>/dev/null || df -k / | awk 'NR==2 {print $4}'`
  # Check if we got a valid number
  if [ -z "$JITSI_AVAILABLE_DISK_KB" ] || ! expr "$JITSI_AVAILABLE_DISK_KB" : '[0-9]*$' >/dev/null; then
    JITSI_AVAILABLE_DISK_KB=0
  fi
  JITSI_AVAILABLE_DISK_GB=`expr $JITSI_AVAILABLE_DISK_KB / 1024 / 1024 2>/dev/null || echo 0`
  
  # Check memory
  if [ $JITSI_TOTAL_MEMORY_MB -lt $JITSI_MIN_MEMORY_MB ]; then
    __warning "System has ${JITSI_TOTAL_MEMORY_MB}MB RAM, recommended minimum is ${JITSI_MIN_MEMORY_MB}MB"
    __warning "Performance may be degraded with limited memory"
  else
    __success "Memory: ${JITSI_TOTAL_MEMORY_MB}MB ${JITSI_CHECKMARK}"
  fi
  
  # Check CPU cores
  if [ $JITSI_CPU_CORES -lt $JITSI_MIN_CPU_CORES ]; then
    __warning "System has ${JITSI_CPU_CORES} CPU cores, recommended minimum is ${JITSI_MIN_CPU_CORES}"
    __warning "Performance may be impacted with fewer CPU cores"
  else
    __success "CPU Cores: ${JITSI_CPU_CORES} ${JITSI_CHECKMARK}"
  fi
  
  # Check disk space
  if [ $JITSI_AVAILABLE_DISK_GB -lt $JITSI_MIN_DISK_GB ]; then
    __error "Insufficient disk space: ${JITSI_AVAILABLE_DISK_GB}GB available, ${JITSI_MIN_DISK_GB}GB required"
    exit $JITSI_EXIT_PREREQ
  else
    __success "Disk Space: ${JITSI_AVAILABLE_DISK_GB}GB available ${JITSI_CHECKMARK}"
  fi
  
  # Store values for optimization
  JITSI_SYSTEM_MEMORY_MB=$JITSI_TOTAL_MEMORY_MB
  JITSI_SYSTEM_CPU_CORES=$JITSI_CPU_CORES
  JITSI_SYSTEM_DISK_GB=$JITSI_AVAILABLE_DISK_GB
}

__optimize_for_host() {
  # Calculate container memory limits based on total system memory
  if [ $JITSI_SYSTEM_MEMORY_MB -gt 8192 ]; then
    # System has more than 8GB RAM
    JITSI_CONTAINER_MEMORY_LIMIT="2048m"
    JITSI_SHARED_MEMORY_SIZE="1024m"
  elif [ $JITSI_SYSTEM_MEMORY_MB -gt 4096 ]; then
    # System has 4-8GB RAM
    JITSI_CONTAINER_MEMORY_LIMIT="1024m"
    JITSI_SHARED_MEMORY_SIZE="512m"
  else
    # System has less than 4GB RAM
    JITSI_CONTAINER_MEMORY_LIMIT="512m"
    JITSI_SHARED_MEMORY_SIZE="256m"
  fi
  
  __info "Container memory limit set to: $JITSI_CONTAINER_MEMORY_LIMIT"
  __info "Shared memory size set to: $JITSI_SHARED_MEMORY_SIZE"
}

__check_prerequisites() {
  __header "Checking Prerequisites"
  
  # Check for required commands
  for cmd in curl systemctl nginx docker; do
    if ! command -v $cmd >/dev/null 2>&1; then
      case $cmd in
        nginx)
          __error "nginx is not installed. Please install nginx first:"
          case "$JITSI_DISTRO_FAMILY" in
            debian)
              __error "  sudo apt update && sudo apt install -y nginx"
              ;;
            rhel)
              __error "  sudo dnf install -y nginx"
              ;;
          esac
          exit $JITSI_EXIT_PREREQ
          ;;
        docker)
          __warning "Docker is not installed. It will be installed automatically."
          ;;
        *)
          __error "Required command '$cmd' is not installed"
          exit $JITSI_EXIT_PREREQ
          ;;
      esac
    fi
  done
  
  # Check for mail server
  if [ "$JITSI_USE_HOST_MAILSERVER" = "true" ]; then
    if ! command -v postfix >/dev/null 2>&1 && ! command -v sendmail >/dev/null 2>&1; then
      __error "No mail server (postfix or sendmail) found on the host"
      __error "Please install a mail server first:"
      case "$JITSI_DISTRO_FAMILY" in
        debian)
          __error "  sudo apt update && sudo apt install -y postfix"
          ;;
        rhel)
          __error "  sudo dnf install -y postfix"
          ;;
      esac
      exit $JITSI_EXIT_PREREQ
    fi
  fi
  
  # Create nginx vhosts directory if missing
  if [ ! -d /etc/nginx/vhosts ]; then
    mkdir -p /etc/nginx/vhosts || {
      __error "Failed to create /etc/nginx/vhosts directory"
      exit $JITSI_EXIT_PERMISSION
    }
  fi
  
  # Test internet connectivity
  __progress "Testing internet connectivity..."
  if ! ping -c 1 -W $JITSI_NETWORK_TIMEOUT 8.8.8.8 >/dev/null 2>&1; then
    __error "No internet connectivity detected"
    exit $JITSI_EXIT_NETWORK
  fi
  
  __success "All prerequisites satisfied"
}

# Section 6: Error Handling and Cleanup Functions
__cleanup() {
  JITSI_CLEANUP_ON_ERROR="${1:-false}"
  
  # Always remove temporary files
  if [ -d "$JITSI_TEMP_DIR" ]; then
    rm -rf "$JITSI_TEMP_DIR"
  fi
  
  # Full cleanup only on error
  if [ "$JITSI_CLEANUP_ON_ERROR" = "true" ]; then
    __warning "Performing cleanup due to installation failure..."
    __cleanup_containers
    __cleanup_nginx_configs
    
    # Remove installation directory
    if [ -d "$JITSI_BASE_DIR" ]; then
      rm -rf "$JITSI_BASE_DIR"
    fi
  fi
}

__cleanup_containers() {
  __info "Stopping and removing containers..."
  
  # List of all container names
  JITSI_CONTAINERS="mariadb valkey keycloak server prosody jicofo jvb etherpad excalidraw jibri coturn prometheus grafana grafana-public jaeger uptime-kuma"
  
  for container in $JITSI_CONTAINERS; do
    JITSI_CONTAINER_NAME="jitsi-${container}"
    if docker ps -a --format '{{.Names}}' | grep -q "^${JITSI_CONTAINER_NAME}$"; then
      docker stop "$JITSI_CONTAINER_NAME" 2>/dev/null || true
      docker rm "$JITSI_CONTAINER_NAME" 2>/dev/null || true
    fi
  done
  
  # Remove Docker network
  if docker network ls --format '{{.Name}}' | grep -q "^${JITSI_DOCKER_NETWORK_NAME}$"; then
    docker network rm "$JITSI_DOCKER_NETWORK_NAME" 2>/dev/null || true
  fi
}

__cleanup_nginx_configs() {
  __info "Removing nginx configurations..."
  
  # Remove all generated vhost files
  for subdomain in "" meet auth admin grafana stats uptime whiteboard pad api metrics trace; do
    if [ -z "$subdomain" ]; then
      JITSI_VHOST_FILE="/etc/nginx/vhosts/${JITSI_DOMAIN}.conf"
    else
      JITSI_VHOST_FILE="/etc/nginx/vhosts/${subdomain}.${JITSI_DOMAIN}.conf"
    fi
    
    if [ -f "$JITSI_VHOST_FILE" ]; then
      rm -f "$JITSI_VHOST_FILE"
    fi
  done
  
  # Test and reload nginx
  if nginx -t >/dev/null 2>&1; then
    systemctl reload nginx
  fi
}

__handle_error() {
  JITSI_ERROR_MSG="$1"
  JITSI_ERROR_LINE="${2:-}"
  JITSI_ERROR_CODE="${3:-$JITSI_EXIT_ERROR}"
  
  __error "Installation failed: $JITSI_ERROR_MSG"
  if [ -n "$JITSI_ERROR_LINE" ]; then
    __error "Error occurred at line: $JITSI_ERROR_LINE"
  fi
  
  __cleanup "true"
  exit $JITSI_ERROR_CODE
}

# Trap handlers
trap '__cleanup' EXIT
trap '__handle_error "Interrupted by user" "" $JITSI_EXIT_ERROR' INT TERM
trap '__handle_error "Script error" "$LINENO" $JITSI_EXIT_ERROR' ERR

# Section 7: Command Line Argument Parsing
__show_help() {
  printf "\n"
  printf "${JITSI_BOLD}NAME${JITSI_NC}\n"
  printf "    %s - Enterprise Jitsi Meet + Keycloak automated installer\n\n" "$APPNAME"
  
  printf "${JITSI_BOLD}SYNOPSIS${JITSI_NC}\n"
  printf "    %s [OPTIONS]\n\n" "$APPNAME"
  
  printf "${JITSI_BOLD}DESCRIPTION${JITSI_NC}\n"
  printf "    Automated installation system for enterprise Jitsi Meet deployment\n"
  printf "    with Keycloak authentication, monitoring stack, and comprehensive\n"
  printf "    automation features.\n\n"
  
  printf "${JITSI_BOLD}OPTIONS${JITSI_NC}\n"
  printf "    ${JITSI_BOLD}--help${JITSI_NC}\n"
  printf "        Display this help message and exit\n\n"
  
  printf "    ${JITSI_BOLD}--version${JITSI_NC}\n"
  printf "        Display version information and exit\n\n"
  
  printf "    ${JITSI_BOLD}--dry-run${JITSI_NC}\n"
  printf "        Generate configuration without installing\n\n"
  
  printf "    ${JITSI_BOLD}--verbose${JITSI_NC}\n"
  printf "        Enable verbose output\n\n"
  
  printf "    ${JITSI_BOLD}--quiet${JITSI_NC}\n"
  printf "        Suppress non-essential output\n\n"
  
  printf "    ${JITSI_BOLD}--raw${JITSI_NC}\n"
  printf "        Output raw text without colors or symbols\n\n"
  
  printf "    ${JITSI_BOLD}--domain${JITSI_NC} DOMAIN\n"
  printf "        Set the domain name (e.g., meet.example.com)\n\n"
  
  printf "    ${JITSI_BOLD}--email${JITSI_NC} EMAIL\n"
  printf "        Set the administrator email address\n\n"
  
  printf "    ${JITSI_BOLD}--timezone${JITSI_NC} TIMEZONE\n"
  printf "        Set the timezone (default: America/New_York)\n\n"
  
  printf "    ${JITSI_BOLD}--backup-dir${JITSI_NC} PATH\n"
  printf "        Set custom backup directory (default: /opt/jitsi/rootfs/backups)\n\n"
  
  printf "    ${JITSI_BOLD}--debug${JITSI_NC}\n"
  printf "        Enable debug mode with detailed logging\n\n"
  
  printf "${JITSI_BOLD}EXAMPLES${JITSI_NC}\n"
  printf "    # Interactive installation\n"
  printf "    sudo %s\n\n" "$APPNAME"
  
  printf "    # Automated installation with parameters\n"
  printf "    sudo %s --domain meet.example.com --email admin@example.com\n\n" "$APPNAME"
  
  printf "    # Dry run to preview configuration\n"
  printf "    sudo %s --dry-run --domain meet.example.com\n\n" "$APPNAME"
  
  printf "    # Installation via curl\n"
  printf "    curl -q -LSsf https://github.com/gistmgr/jitsi/raw/refs/heads/main/install.sh | sh\n\n"
  
  printf "${JITSI_BOLD}REQUIREMENTS${JITSI_NC}\n"
  printf "    - Root or sudo access\n"
  printf "    - Supported Linux distribution\n"
  printf "    - Minimum 2GB RAM, 2 CPU cores, 10GB disk space\n"
  printf "    - Valid SSL certificates for the domain\n"
  printf "    - nginx web server installed\n"
  printf "    - Host mail server (postfix or sendmail)\n\n"
  
  printf "${JITSI_BOLD}NOTES${JITSI_NC}\n"
  printf "    After installation, access your Jitsi Meet instance at:\n"
  printf "    https://[your-domain]/\n\n"
  
  printf "    Default passwords are generated and stored temporarily in:\n"
  printf "    %s/.passwords\n\n" "$JITSI_BASE_DIR"
  
  printf "    For security, delete the password file after saving credentials.\n\n"
  
  printf "${JITSI_BOLD}COPYRIGHT${JITSI_NC}\n"
  printf "    Copyright (c) 2025 Jason Hempstead, Casjays Developments\n"
  printf "    License: WTFPL\n\n"
}

__show_version() {
  printf "%s version %s\n" "$APPNAME" "$VERSION"
  printf "Copyright (c) 2025 Jason Hempstead, Casjays Developments\n"
  printf "License: WTFPL\n"
  printf "Written by: Jason Hempstead\n"
}

__parse_arguments() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --help)
        __show_help
        exit $JITSI_EXIT_SUCCESS
        ;;
      --version)
        __show_version
        exit $JITSI_EXIT_SUCCESS
        ;;
      --dry-run)
        JITSI_DRY_RUN="true"
        shift
        ;;
      --verbose)
        JITSI_VERBOSE_MODE="true"
        shift
        ;;
      --quiet)
        JITSI_QUIET_MODE="true"
        shift
        ;;
      --raw)
        JITSI_RAW_OUTPUT="true"
        shift
        ;;
      --domain)
        if [ -z "$2" ] || [ "${2#-}" != "$2" ]; then
          __error "Option --domain requires a value"
          exit $JITSI_EXIT_USAGE
        fi
        JITSI_DOMAIN="$2"
        shift 2
        ;;
      --email)
        if [ -z "$2" ] || [ "${2#-}" != "$2" ]; then
          __error "Option --email requires a value"
          exit $JITSI_EXIT_USAGE
        fi
        JITSI_ADMIN_EMAIL="$2"
        shift 2
        ;;
      --timezone)
        if [ -z "$2" ] || [ "${2#-}" != "$2" ]; then
          __error "Option --timezone requires a value"
          exit $JITSI_EXIT_USAGE
        fi
        JITSI_TIMEZONE="$2"
        shift 2
        ;;
      --backup-dir)
        if [ -z "$2" ] || [ "${2#-}" != "$2" ]; then
          __error "Option --backup-dir requires a value"
          exit $JITSI_EXIT_USAGE
        fi
        JITSI_BACKUP_DIR="$2"
        shift 2
        ;;
      --debug)
        JITSI_DEBUG_MODE="true"
        JITSI_VERBOSE_MODE="true"
        shift
        ;;
      -*)
        __error "Unknown option: $1"
        __error "Use --help for usage information"
        exit $JITSI_EXIT_USAGE
        ;;
      *)
        __error "Unexpected argument: $1"
        __error "Use --help for usage information"
        exit $JITSI_EXIT_USAGE
        ;;
    esac
  done
  
  # Validate domain if provided
  if [ -n "$JITSI_DOMAIN" ]; then
    __validate_domain "$JITSI_DOMAIN" || {
      __error "Invalid domain format: $JITSI_DOMAIN"
      exit $JITSI_EXIT_USAGE
    }
  fi
  
  # Validate email if provided
  if [ -n "$JITSI_ADMIN_EMAIL" ]; then
    __validate_email "$JITSI_ADMIN_EMAIL" || {
      __error "Invalid email format: $JITSI_ADMIN_EMAIL"
      exit $JITSI_EXIT_USAGE
    }
  fi
  
  # Set defaults
  JITSI_TIMEZONE="${JITSI_TIMEZONE:-$JITSI_DEFAULT_TIMEZONE}"
  JITSI_BACKUP_DIR="${JITSI_BACKUP_DIR:-$JITSI_ROOTFS_DIR/backups}"
}

__validate_domain() {
  JITSI_VALIDATE_DOMAIN="$1"
  
  # Basic domain validation using case statement
  case "$JITSI_VALIDATE_DOMAIN" in
    *.*)
      # Contains at least one dot
      case "$JITSI_VALIDATE_DOMAIN" in
        *..*)
          # Contains consecutive dots
          return 1
          ;;
        .*|*.)
          # Starts or ends with dot
          return 1
          ;;
        *[!a-zA-Z0-9.-]*)
          # Contains invalid characters
          return 1
          ;;
        *)
          # Check length (max 253 characters)
          if [ `printf "%s" "$JITSI_VALIDATE_DOMAIN" | wc -c` -gt 253 ]; then
            return 1
          fi
          return 0
          ;;
      esac
      ;;
    *)
      # No dots found
      return 1
      ;;
  esac
}

__validate_email() {
  JITSI_VALIDATE_EMAIL="$1"
  
  # Basic email validation using case statement
  case "$JITSI_VALIDATE_EMAIL" in
    *@*.*)
      # Contains @ and domain has dot
      case "$JITSI_VALIDATE_EMAIL" in
        *@*@*)
          # Multiple @ symbols
          return 1
          ;;
        @*|*@)
          # Starts or ends with @
          return 1
          ;;
        *[!a-zA-Z0-9.@_+-]*)
          # Contains invalid characters
          return 1
          ;;
        *)
          return 0
          ;;
      esac
      ;;
    *)
      # Invalid format
      return 1
      ;;
  esac
}

# Section 8: Docker Installation and Management
__detect_docker() {
  JITSI_DOCKER_INSTALLED="false"
  JITSI_DOCKER_REPO_EXISTS="false"
  
  # Check if Docker is installed
  if command -v docker >/dev/null 2>&1; then
    if docker version >/dev/null 2>&1; then
      JITSI_DOCKER_INSTALLED="true"
      __info "Docker is already installed"
    fi
  fi
  
  # Check if Docker service is active
  if [ "$JITSI_DOCKER_INSTALLED" = "true" ]; then
    if ! systemctl is-active --quiet docker; then
      __warning "Docker is installed but not running"
      systemctl start docker || __handle_error "Failed to start Docker service"
    fi
  fi
  
  # Check for existing Docker repository
  case "$JITSI_DISTRO_FAMILY" in
    debian)
      if [ -f /etc/apt/sources.list.d/docker.list ]; then
        JITSI_DOCKER_REPO_EXISTS="true"
      fi
      ;;
    rhel)
      if [ -f /etc/yum.repos.d/docker-ce.repo ]; then
        JITSI_DOCKER_REPO_EXISTS="true"
      fi
      ;;
  esac
}

__install_docker() {
  __header "Installing Docker"
  
  case "$JITSI_DISTRO_FAMILY" in
    debian)
      # Install prerequisites
      __progress "Installing Docker prerequisites..."
      apt-get update || __handle_error "Failed to update package list"
      apt-get install -y ca-certificates curl gnupg lsb-release || __handle_error "Failed to install prerequisites"
      
      # Add Docker's official GPG key
      if [ "$JITSI_DOCKER_REPO_EXISTS" = "false" ]; then
        __progress "Adding Docker repository..."
        mkdir -p /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/${JITSI_OS_ID}/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        
        printf "deb [arch=`dpkg --print-architecture` signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/%s %s stable\n" \
          "$JITSI_OS_ID" "`lsb_release -cs`" > /etc/apt/sources.list.d/docker.list
      fi
      
      # Install Docker
      __progress "Installing Docker packages..."
      apt-get update || __handle_error "Failed to update package list"
      apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || __handle_error "Failed to install Docker"
      ;;
      
    rhel)
      # Remove old versions
      __progress "Removing old Docker versions..."
      dnf remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine 2>/dev/null || true
      
      # Add Docker repository
      if [ "$JITSI_DOCKER_REPO_EXISTS" = "false" ]; then
        __progress "Adding Docker repository..."
        dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo || __handle_error "Failed to add Docker repository"
      fi
      
      # Install Docker
      __progress "Installing Docker packages..."
      dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || __handle_error "Failed to install Docker"
      ;;
  esac
  
  # Enable and start Docker
  __progress "Enabling Docker service..."
  systemctl enable docker || __handle_error "Failed to enable Docker service"
  
  # Try to start Docker
  if ! systemctl start docker 2>/dev/null; then
    # Get Docker error for logging
    JITSI_DOCKER_ERROR=`systemctl status docker 2>&1 | tail -20`
    __debug "Docker startup error: $JITSI_DOCKER_ERROR"
    __handle_error "Failed to start Docker service"
  fi
  
  # Verify installation
  if docker version >/dev/null 2>&1; then
    __success "Docker installed successfully"
  else
    __handle_error "Docker installation verification failed"
  fi
}

__detect_docker_bridge() {
  __info "Auto-detecting Docker bridge IP address..."
  
  # Try multiple methods to detect Docker bridge IP
  JITSI_DOCKER_BRIDGE_IP=""
  
  # Method 1: Docker network inspect
  if [ -z "$JITSI_DOCKER_BRIDGE_IP" ]; then
    JITSI_DOCKER_BRIDGE_IP=`docker network inspect bridge 2>/dev/null | grep -E '"Gateway"' | head -1 | cut -d'"' -f4`
  fi
  
  # Method 2: ip addr command
  if [ -z "$JITSI_DOCKER_BRIDGE_IP" ] && command -v ip >/dev/null 2>&1; then
    JITSI_DOCKER_BRIDGE_IP=`ip addr show docker0 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d/ -f1`
  fi
  
  # Method 3: ip route command
  if [ -z "$JITSI_DOCKER_BRIDGE_IP" ] && command -v ip >/dev/null 2>&1; then
    JITSI_DOCKER_BRIDGE_IP=`ip route | grep docker0 | grep src | awk '{print $NF}'`
  fi
  
  # Validate IP format
  if [ -n "$JITSI_DOCKER_BRIDGE_IP" ]; then
    case "$JITSI_DOCKER_BRIDGE_IP" in
      *.*.*.*)
        __info "Docker bridge IP detected: $JITSI_DOCKER_BRIDGE_IP"
        ;;
      *)
        JITSI_DOCKER_BRIDGE_IP="172.17.0.1"
        __warning "Invalid Docker bridge IP detected, using default: $JITSI_DOCKER_BRIDGE_IP"
        ;;
    esac
  else
    JITSI_DOCKER_BRIDGE_IP="172.17.0.1"
    __warning "Could not detect Docker bridge IP, using default: $JITSI_DOCKER_BRIDGE_IP"
  fi
}

__create_docker_network() {
  __info "Creating Docker network: $JITSI_DOCKER_NETWORK_NAME"
  
  # Check if network already exists
  if docker network ls --format '{{.Name}}' | grep -q "^${JITSI_DOCKER_NETWORK_NAME}$"; then
    __info "Docker network '$JITSI_DOCKER_NETWORK_NAME' already exists"
  else
    docker network create "$JITSI_DOCKER_NETWORK_NAME" || __handle_error "Failed to create Docker network"
    __success "Docker network created successfully"
  fi
}

# Section 9: Directory Structure and Permissions
__create_directory_structure() {
  __header "Creating Directory Structure"
  
  # Define all directories
  JITSI_CONFIG_DIRS="nginx keycloak jitsi prosody jicofo jvb etherpad excalidraw prometheus grafana uptime-kuma jaeger"
  JITSI_DATA_DIRS="keycloak jitsi prosody jicofo jvb etherpad excalidraw prometheus grafana uptime-kuma jaeger recordings transcripts"
  JITSI_DB_DIRS="mariadb valkey"
  JITSI_ADDITIONAL_DIRS="logs backups backups/daily backups/weekly backups/monthly tmp templates ssl"
  
  # Create base directory
  if [ ! -d "$JITSI_BASE_DIR" ]; then
    mkdir -p "$JITSI_BASE_DIR" || __handle_error "Failed to create base directory"
  fi
  
  # Create rootfs directory
  if [ ! -d "$JITSI_ROOTFS_DIR" ]; then
    mkdir -p "$JITSI_ROOTFS_DIR" || __handle_error "Failed to create rootfs directory"
  fi
  
  # Create config directories
  for dir in $JITSI_CONFIG_DIRS; do
    JITSI_DIR_PATH="$JITSI_ROOTFS_DIR/config/$dir"
    if [ ! -d "$JITSI_DIR_PATH" ]; then
      mkdir -p "$JITSI_DIR_PATH" || __handle_error "Failed to create config directory: $dir"
    fi
  done
  
  # Create data directories
  for dir in $JITSI_DATA_DIRS; do
    JITSI_DIR_PATH="$JITSI_ROOTFS_DIR/data/$dir"
    if [ ! -d "$JITSI_DIR_PATH" ]; then
      mkdir -p "$JITSI_DIR_PATH" || __handle_error "Failed to create data directory: $dir"
    fi
  done
  
  # Create database directories
  for dir in $JITSI_DB_DIRS; do
    JITSI_DIR_PATH="$JITSI_ROOTFS_DIR/db/$dir"
    if [ ! -d "$JITSI_DIR_PATH" ]; then
      mkdir -p "$JITSI_DIR_PATH" || __handle_error "Failed to create database directory: $dir"
    fi
  done
  
  # Create additional directories
  for dir in $JITSI_ADDITIONAL_DIRS; do
    JITSI_DIR_PATH="$JITSI_ROOTFS_DIR/$dir"
    if [ ! -d "$JITSI_DIR_PATH" ]; then
      mkdir -p "$JITSI_DIR_PATH" || __handle_error "Failed to create directory: $dir"
    fi
  done
  
  # Create log directory
  if [ ! -d "$JITSI_SCRIPT_LOG_DIR" ]; then
    mkdir -p "$JITSI_SCRIPT_LOG_DIR" || __handle_error "Failed to create log directory"
  fi
  
  # Create cron log directory
  if [ ! -d "$JITSI_CRON_LOG_DIR" ]; then
    mkdir -p "$JITSI_CRON_LOG_DIR" || __handle_error "Failed to create cron log directory"
  fi
  
  # Create temp directory
  if [ ! -d "$JITSI_TEMP_DIR" ]; then
    mkdir -p "$JITSI_TEMP_DIR" || __handle_error "Failed to create temp directory"
  fi
  
  __success "Directory structure created successfully"
}

__setup_container_permissions() {
  __header "Setting Up Permissions"
  
  # Create system users for container services
  JITSI_SERVICE_USERS="999:prosody 998:jicofo 997:jvb 996:etherpad 995:grafana"
  
  for user_spec in $JITSI_SERVICE_USERS; do
    JITSI_UID=`printf "%s" "$user_spec" | cut -d: -f1`
    JITSI_USERNAME=`printf "%s" "$user_spec" | cut -d: -f2`
    
    # Check if user exists
    if ! id -u "$JITSI_USERNAME" >/dev/null 2>&1; then
      # Find available UID below 999
      JITSI_AVAILABLE_UID="$JITSI_UID"
      while id -u "$JITSI_AVAILABLE_UID" >/dev/null 2>&1; do
        JITSI_AVAILABLE_UID=`expr $JITSI_AVAILABLE_UID - 1`
      done
      
      # Create system user
      useradd -r -u "$JITSI_AVAILABLE_UID" -s /sbin/nologin "$JITSI_USERNAME" || true
    fi
  done
  
  # Set ownership and permissions for config directories
  chown -R root:root "$JITSI_ROOTFS_DIR/config"
  chmod -R 755 "$JITSI_ROOTFS_DIR/config"
  
  # Set ownership for data directories
  chown -R 999:999 "$JITSI_ROOTFS_DIR/data/prosody"
  chown -R 998:998 "$JITSI_ROOTFS_DIR/data/jicofo"
  chown -R 997:997 "$JITSI_ROOTFS_DIR/data/jvb"
  chown -R 996:996 "$JITSI_ROOTFS_DIR/data/etherpad"
  chown -R 995:995 "$JITSI_ROOTFS_DIR/data/grafana"
  chown -R root:root "$JITSI_ROOTFS_DIR/data/keycloak"
  chown -R root:root "$JITSI_ROOTFS_DIR/data/prometheus"
  chown -R root:root "$JITSI_ROOTFS_DIR/data/jaeger"
  chown -R root:root "$JITSI_ROOTFS_DIR/data/uptime-kuma"
  chown -R root:root "$JITSI_ROOTFS_DIR/data/excalidraw"
  chown -R root:root "$JITSI_ROOTFS_DIR/data/recordings"
  chown -R root:root "$JITSI_ROOTFS_DIR/data/transcripts"
  
  # Set permissions for data directories
  chmod -R 755 "$JITSI_ROOTFS_DIR/data"
  
  # Set ownership for database directories
  chown -R 999:999 "$JITSI_ROOTFS_DIR/db/mariadb"
  chown -R 999:999 "$JITSI_ROOTFS_DIR/db/valkey"
  chmod -R 755 "$JITSI_ROOTFS_DIR/db"
  
  # Set permissions for SSL directory
  chmod 755 "$JITSI_ROOTFS_DIR/ssl"
  
  # Set permissions for temporary and backup directories
  chmod 1777 "$JITSI_ROOTFS_DIR/tmp"
  chmod 755 "$JITSI_ROOTFS_DIR/backups"
  chmod 755 "$JITSI_ROOTFS_DIR/logs"
  
  __success "Permissions configured successfully"
}

# Section 10: Environment Configuration Management
__create_env_file() {
  __header "Creating Environment Configuration"
  
  # Generate passwords if not provided
  JITSI_MARIADB_ROOT_PASSWORD="${JITSI_MARIADB_ROOT_PASSWORD:-`__generate_password`}"
  JITSI_MARIADB_PASSWORD="${JITSI_MARIADB_PASSWORD:-`__generate_password`}"
  JITSI_KEYCLOAK_DB_PASSWORD="${JITSI_KEYCLOAK_DB_PASSWORD:-`__generate_password`}"
  JITSI_KEYCLOAK_ADMIN_PASSWORD="${JITSI_KEYCLOAK_ADMIN_PASSWORD:-`__generate_password`}"
  JITSI_JICOFO_AUTH_PASSWORD="${JITSI_JICOFO_AUTH_PASSWORD:-`__generate_password`}"
  JITSI_JVB_AUTH_PASSWORD="${JITSI_JVB_AUTH_PASSWORD:-`__generate_password`}"
  JITSI_JIBRI_XMPP_PASSWORD="${JITSI_JIBRI_XMPP_PASSWORD:-`__generate_password`}"
  JITSI_JIBRI_RECORDER_PASSWORD="${JITSI_JIBRI_RECORDER_PASSWORD:-`__generate_password`}"
  JITSI_JWT_APP_SECRET="${JITSI_JWT_APP_SECRET:-`__generate_password`}"
  JITSI_TURN_SECRET="${JITSI_TURN_SECRET:-`__generate_password`}"
  JITSI_GRAFANA_ADMIN_PASSWORD="${JITSI_GRAFANA_ADMIN_PASSWORD:-`__generate_password`}"
  JITSI_UPTIME_KUMA_PASSWORD="${JITSI_UPTIME_KUMA_PASSWORD:-`__generate_password`}"
  
  # Create .env file
  cat > "$JITSI_ENV_FILE" << EOF
#!/bin/sh
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
##@Version           :  ${VERSION}
# @@Author           :  Jason Hempstead
# @@Contact          :  jason@casjaysdev.pro
# @@License          :  WTFPL
# @@ReadME           :  .env --help
# @@Copyright        :  Copyright: (c) 2025 Jason Hempstead, Casjays Developments
# @@Created          :  `date '+%A, %b %d, %Y %I:%M %p %Z'`
# @@File             :  .env
# @@Description      :  Jitsi Meet Enterprise Configuration
# @@Changelog        :  New File
# @@TODO             :  Better documentation
# @@Other            :  Auto-generated configuration file
# @@Resource         :  
# @@Terminal App     :  no
# @@sudo/root        :  no
# @@Template         :  shell/env
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Organization and Branding
JITSI_ORG_NAME="$JITSI_ORG_NAME"
JITSI_DOMAIN="$JITSI_DOMAIN"
JITSI_ADMIN_EMAIL="$JITSI_ADMIN_EMAIL"
JITSI_TIMEZONE="$JITSI_TIMEZONE"

# Authentication Configuration
JITSI_KEYCLOAK_ADMIN_USER="${JITSI_KEYCLOAK_ADMIN_USER:-administrator@$JITSI_DOMAIN}"
JITSI_KEYCLOAK_ADMIN_PASSWORD="$JITSI_KEYCLOAK_ADMIN_PASSWORD"
JITSI_DEFAULT_ADMIN_USERNAME="$JITSI_DEFAULT_ADMIN_USERNAME"
JITSI_JWT_APP_SECRET="$JITSI_JWT_APP_SECRET"

# Mail Server Configuration
JITSI_USE_HOST_MAILSERVER="$JITSI_USE_HOST_MAILSERVER"
JITSI_SMTP_HOST="$JITSI_SMTP_HOST"
JITSI_SMTP_PORT="$JITSI_SMTP_PORT"
JITSI_SMTP_AUTH="$JITSI_SMTP_AUTH"
JITSI_SMTP_TLS="$JITSI_SMTP_TLS"
JITSI_SMTP_FROM_NAME="$JITSI_SMTP_FROM_NAME"
JITSI_SMTP_FROM_EMAIL="no-reply@$JITSI_DOMAIN"

# Docker Configuration
JITSI_DOCKER_NETWORK_NAME="$JITSI_DOCKER_NETWORK_NAME"
JITSI_DOCKER_BRIDGE_IP="$JITSI_DOCKER_BRIDGE_IP"
JITSI_CONTAINER_MEMORY_LIMIT="$JITSI_CONTAINER_MEMORY_LIMIT"
JITSI_SHARED_MEMORY_SIZE="$JITSI_SHARED_MEMORY_SIZE"

# Service Configuration
JITSI_ROOM_CLEANUP_INTERVAL="$JITSI_ROOM_CLEANUP_INTERVAL"
JITSI_ANONYMOUS_RATE_LIMIT="$JITSI_ANONYMOUS_RATE_LIMIT"
JITSI_AUTHENTICATED_RATE_LIMIT="$JITSI_AUTHENTICATED_RATE_LIMIT"

# Monitoring Configuration
JITSI_UPTIME_KUMA_GROUP_NAME="$JITSI_ORG_NAME Services"
JITSI_UPTIME_KUMA_PASSWORD="$JITSI_UPTIME_KUMA_PASSWORD"
JITSI_GRAFANA_ADMIN_PASSWORD="$JITSI_GRAFANA_ADMIN_PASSWORD"

# Database Configuration
JITSI_MARIADB_ROOT_PASSWORD="$JITSI_MARIADB_ROOT_PASSWORD"
JITSI_MARIADB_DATABASE="jitsi"
JITSI_MARIADB_USER="jitsi"
JITSI_MARIADB_PASSWORD="$JITSI_MARIADB_PASSWORD"
JITSI_KEYCLOAK_DB_PASSWORD="$JITSI_KEYCLOAK_DB_PASSWORD"

# XMPP Configuration
JITSI_JICOFO_AUTH_PASSWORD="$JITSI_JICOFO_AUTH_PASSWORD"
JITSI_JVB_AUTH_PASSWORD="$JITSI_JVB_AUTH_PASSWORD"
JITSI_JIBRI_XMPP_PASSWORD="$JITSI_JIBRI_XMPP_PASSWORD"
JITSI_JIBRI_RECORDER_PASSWORD="$JITSI_JIBRI_RECORDER_PASSWORD"
JITSI_TURN_SECRET="$JITSI_TURN_SECRET"

# Path Configuration
JITSI_BASE_DIR="$JITSI_BASE_DIR"
JITSI_ROOTFS_DIR="$JITSI_ROOTFS_DIR"
JITSI_BACKUP_DIR="$JITSI_BACKUP_DIR"
JITSI_SSL_CERT_PATH="$JITSI_SSL_CERT_PATH"
JITSI_SSL_KEY_PATH="$JITSI_SSL_KEY_PATH"

# System Configuration
JITSI_SYSTEM_MEMORY_MB="$JITSI_SYSTEM_MEMORY_MB"
JITSI_SYSTEM_CPU_CORES="$JITSI_SYSTEM_CPU_CORES"
JITSI_SYSTEM_DISK_GB="$JITSI_SYSTEM_DISK_GB"

# Export all variables
export JITSI_ORG_NAME JITSI_DOMAIN JITSI_ADMIN_EMAIL JITSI_TIMEZONE
export JITSI_KEYCLOAK_ADMIN_USER JITSI_KEYCLOAK_ADMIN_PASSWORD
export JITSI_DEFAULT_ADMIN_USERNAME JITSI_JWT_APP_SECRET
export JITSI_USE_HOST_MAILSERVER JITSI_SMTP_HOST JITSI_SMTP_PORT
export JITSI_SMTP_AUTH JITSI_SMTP_TLS JITSI_SMTP_FROM_NAME JITSI_SMTP_FROM_EMAIL
export JITSI_DOCKER_NETWORK_NAME JITSI_DOCKER_BRIDGE_IP
export JITSI_CONTAINER_MEMORY_LIMIT JITSI_SHARED_MEMORY_SIZE
export JITSI_ROOM_CLEANUP_INTERVAL JITSI_ANONYMOUS_RATE_LIMIT JITSI_AUTHENTICATED_RATE_LIMIT
export JITSI_UPTIME_KUMA_GROUP_NAME JITSI_UPTIME_KUMA_PASSWORD JITSI_GRAFANA_ADMIN_PASSWORD
export JITSI_MARIADB_ROOT_PASSWORD JITSI_MARIADB_DATABASE JITSI_MARIADB_USER
export JITSI_MARIADB_PASSWORD JITSI_KEYCLOAK_DB_PASSWORD
export JITSI_JICOFO_AUTH_PASSWORD JITSI_JVB_AUTH_PASSWORD
export JITSI_JIBRI_XMPP_PASSWORD JITSI_JIBRI_RECORDER_PASSWORD JITSI_TURN_SECRET
export JITSI_BASE_DIR JITSI_ROOTFS_DIR JITSI_BACKUP_DIR
export JITSI_SSL_CERT_PATH JITSI_SSL_KEY_PATH
export JITSI_SYSTEM_MEMORY_MB JITSI_SYSTEM_CPU_CORES JITSI_SYSTEM_DISK_GB
EOF
  
  # Set permissions
  chmod 600 "$JITSI_ENV_FILE"
  chown root:root "$JITSI_ENV_FILE"
  
  __success "Environment configuration created"
}

__load_env_file() {
  if [ -f "$JITSI_ENV_FILE" ]; then
    . "$JITSI_ENV_FILE"
    __info "Loaded existing environment configuration"
  fi
}

__validate_env_configuration() {
  # Check required variables
  JITSI_REQUIRED_VARS="JITSI_DOMAIN JITSI_ADMIN_EMAIL JITSI_ORG_NAME"
  
  for var in $JITSI_REQUIRED_VARS; do
    eval "JITSI_VAR_VALUE=\$$var"
    if [ -z "$JITSI_VAR_VALUE" ]; then
      __error "Required variable $var is not set"
      return 1
    fi
  done
  
  # Validate domain format
  if ! __validate_domain "$JITSI_DOMAIN"; then
    __error "Invalid domain format: $JITSI_DOMAIN"
    return 1
  fi
  
  # Validate email format
  if ! __validate_email "$JITSI_ADMIN_EMAIL"; then
    __error "Invalid email format: $JITSI_ADMIN_EMAIL"
    return 1
  fi
  
  return 0
}

# Section 11: SSL Certificate Management
__detect_ssl_certificates() {
  __header "Detecting SSL Certificates"
  
  JITSI_SSL_FOUND="false"
  
  # Check multiple locations in priority order
  # 1. Check literal "domain" directory
  if [ -f "/etc/letsencrypt/live/domain/fullchain.pem" ] && [ -f "/etc/letsencrypt/live/domain/privkey.pem" ]; then
    JITSI_SSL_CERT_PATH="/etc/letsencrypt/live/domain/fullchain.pem"
    JITSI_SSL_KEY_PATH="/etc/letsencrypt/live/domain/privkey.pem"
    JITSI_SSL_FOUND="true"
    __info "Found SSL certificates in /etc/letsencrypt/live/domain/"
  fi
  
  # 2. Check with actual domain name
  if [ "$JITSI_SSL_FOUND" = "false" ] && [ -n "$JITSI_DOMAIN" ]; then
    if [ -f "/etc/letsencrypt/live/$JITSI_DOMAIN/fullchain.pem" ] && [ -f "/etc/letsencrypt/live/$JITSI_DOMAIN/privkey.pem" ]; then
      JITSI_SSL_CERT_PATH="/etc/letsencrypt/live/$JITSI_DOMAIN/fullchain.pem"
      JITSI_SSL_KEY_PATH="/etc/letsencrypt/live/$JITSI_DOMAIN/privkey.pem"
      JITSI_SSL_FOUND="true"
      __info "Found SSL certificates in /etc/letsencrypt/live/$JITSI_DOMAIN/"
    fi
  fi
  
  # 3. Check standard SSL directory
  if [ "$JITSI_SSL_FOUND" = "false" ] && [ -n "$JITSI_DOMAIN" ]; then
    if [ -f "/etc/ssl/certs/$JITSI_DOMAIN.crt" ] && [ -f "/etc/ssl/private/$JITSI_DOMAIN.key" ]; then
      JITSI_SSL_CERT_PATH="/etc/ssl/certs/$JITSI_DOMAIN.crt"
      JITSI_SSL_KEY_PATH="/etc/ssl/private/$JITSI_DOMAIN.key"
      JITSI_SSL_FOUND="true"
      __info "Found SSL certificates in /etc/ssl/"
    fi
  fi
  
  # 4. Check alternative location
  if [ "$JITSI_SSL_FOUND" = "false" ] && [ -n "$JITSI_DOMAIN" ]; then
    if [ -f "/etc/pki/tls/certs/$JITSI_DOMAIN.crt" ] && [ -f "/etc/pki/tls/private/$JITSI_DOMAIN.key" ]; then
      JITSI_SSL_CERT_PATH="/etc/pki/tls/certs/$JITSI_DOMAIN.crt"
      JITSI_SSL_KEY_PATH="/etc/pki/tls/private/$JITSI_DOMAIN.key"
      JITSI_SSL_FOUND="true"
      __info "Found SSL certificates in /etc/pki/tls/"
    fi
  fi
  
  # Hard fail if certificates not found
  if [ "$JITSI_SSL_FOUND" = "false" ]; then
    __error "SSL certificates not found!"
    __error "Please ensure SSL certificates are installed before running this installer."
    __error ""
    __error "Expected locations:"
    __error "  - /etc/letsencrypt/live/$JITSI_DOMAIN/fullchain.pem"
    __error "  - /etc/ssl/certs/$JITSI_DOMAIN.crt"
    __error "  - /etc/pki/tls/certs/$JITSI_DOMAIN.crt"
    __error ""
    __error "To obtain Let's Encrypt certificates, run:"
    __error "  certbot certonly --standalone -d $JITSI_DOMAIN -d *.$JITSI_DOMAIN"
    
    # Send email with instructions
    __send_ssl_instructions_email
    
    exit $JITSI_EXIT_PREREQ
  fi
  
  __success "SSL certificates found and validated"
}

__send_ssl_instructions_email() {
  if command -v mail >/dev/null 2>&1 && [ -n "$JITSI_DOMAIN" ]; then
    JITSI_SSL_EMAIL_BODY=`cat << EOF
SSL Certificate Setup Required for Jitsi Meet Installation

The Jitsi Meet installer could not find SSL certificates for your domain: $JITSI_DOMAIN

To proceed with the installation, you need to obtain and install SSL certificates.

Option 1: Let's Encrypt (Recommended)
-------------------------------------
Run the following command to obtain free SSL certificates:

  certbot certonly --standalone -d $JITSI_DOMAIN -d *.$JITSI_DOMAIN

Make sure port 80 is available during certificate generation.

Option 2: Commercial SSL Certificate
------------------------------------
If you have purchased SSL certificates, place them in one of these locations:

  Certificate: /etc/ssl/certs/$JITSI_DOMAIN.crt
  Private Key: /etc/ssl/private/$JITSI_DOMAIN.key

Or:

  Certificate: /etc/pki/tls/certs/$JITSI_DOMAIN.crt
  Private Key: /etc/pki/tls/private/$JITSI_DOMAIN.key

After installing certificates, run the installer again.

Best regards,
Jitsi Meet Installer
EOF
`
    printf "%s" "$JITSI_SSL_EMAIL_BODY" | mail -s "SSL Certificate Required - Jitsi Meet Installation" "root@$JITSI_DOMAIN"
  fi
}

__validate_ssl_certificates() {
  __info "Validating SSL certificates..."
  
  # Check certificate expiration
  if command -v openssl >/dev/null 2>&1; then
    JITSI_CERT_EXPIRY=`openssl x509 -in "$JITSI_SSL_CERT_PATH" -noout -enddate 2>/dev/null | cut -d= -f2`
    if [ -n "$JITSI_CERT_EXPIRY" ]; then
      __info "Certificate expires: $JITSI_CERT_EXPIRY"
      
      # Check if certificate is expired
      JITSI_CERT_END_EPOCH=`date -d "$JITSI_CERT_EXPIRY" +%s 2>/dev/null || date +%s`
      JITSI_CURRENT_EPOCH=`date +%s`
      
      if [ $JITSI_CERT_END_EPOCH -lt $JITSI_CURRENT_EPOCH ]; then
        __error "SSL certificate has expired!"
        exit $JITSI_EXIT_PREREQ
      elif [ $JITSI_CERT_END_EPOCH -lt `expr $JITSI_CURRENT_EPOCH + 604800` ]; then
        __warning "SSL certificate expires in less than 7 days!"
      fi
    fi
    
    # Validate certificate and key match
    # First check if it's an RSA or EC key
    JITSI_KEY_TYPE=`openssl pkey -in "$JITSI_SSL_KEY_PATH" -noout -text 2>/dev/null | grep -E "RSA Private|EC Private" | head -1`
    
    if echo "$JITSI_KEY_TYPE" | grep -q "RSA"; then
      # RSA key validation
      JITSI_CERT_MODULUS=`openssl x509 -in "$JITSI_SSL_CERT_PATH" -noout -modulus 2>/dev/null | md5sum | cut -d' ' -f1`
      JITSI_KEY_MODULUS=`openssl rsa -in "$JITSI_SSL_KEY_PATH" -noout -modulus 2>/dev/null | md5sum | cut -d' ' -f1`
      
      if [ "$JITSI_CERT_MODULUS" != "$JITSI_KEY_MODULUS" ]; then
        __error "SSL certificate and private key do not match!"
        exit $JITSI_EXIT_PREREQ
      fi
    else
      # EC key validation - compare public keys
      JITSI_CERT_PUBKEY=`openssl x509 -in "$JITSI_SSL_CERT_PATH" -noout -pubkey 2>/dev/null | openssl md5`
      JITSI_KEY_PUBKEY=`openssl pkey -in "$JITSI_SSL_KEY_PATH" -pubout 2>/dev/null | openssl md5`
      
      if [ "$JITSI_CERT_PUBKEY" != "$JITSI_KEY_PUBKEY" ]; then
        __error "SSL certificate and private key do not match!"
        exit $JITSI_EXIT_PREREQ
      fi
    fi
  fi
  
  __success "SSL certificates validated successfully"
}

# Section 12: Interactive Configuration
__detect_domain() {
  # Try to auto-detect domain from hostname
  JITSI_DETECTED_DOMAIN=""
  
  # Method 1: hostname -d
  if [ -z "$JITSI_DETECTED_DOMAIN" ] && command -v hostname >/dev/null 2>&1; then
    JITSI_DETECTED_DOMAIN=`hostname -d 2>/dev/null`
    if [ "$JITSI_DETECTED_DOMAIN" = "(none)" ] || [ "$JITSI_DETECTED_DOMAIN" = "localdomain" ]; then
      JITSI_DETECTED_DOMAIN=""
    fi
  fi
  
  # Method 2: hostname -f
  if [ -z "$JITSI_DETECTED_DOMAIN" ] && command -v hostname >/dev/null 2>&1; then
    JITSI_FULL_HOSTNAME=`hostname -f 2>/dev/null`
    case "$JITSI_FULL_HOSTNAME" in
      *.*)
        JITSI_DETECTED_DOMAIN="$JITSI_FULL_HOSTNAME"
        ;;
    esac
  fi
  
  # Validate detected domain
  if [ -n "$JITSI_DETECTED_DOMAIN" ]; then
    if __validate_domain "$JITSI_DETECTED_DOMAIN"; then
      printf "%s" "$JITSI_DETECTED_DOMAIN"
    fi
  fi
}

__generate_password() {
  # Generate secure password using openssl
  if command -v openssl >/dev/null 2>&1; then
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-32
  else
    # Fallback to time-based password
    printf "%s%s" "`date +%s`" "$$" | sha256sum | cut -c1-32
  fi
}

__interactive_config() {
  if [ "$JITSI_QUIET_MODE" = "true" ] || [ "$JITSI_DRY_RUN" = "true" ]; then
    return
  fi
  
  __header "Interactive Configuration"
  
  # Domain configuration
  if [ -z "$JITSI_DOMAIN" ]; then
    JITSI_DEFAULT_DOMAIN=`__detect_domain`
    
    __input "Domain name for your Jitsi Meet instance" "$JITSI_DEFAULT_DOMAIN"
    read JITSI_INPUT_DOMAIN
    
    if [ -z "$JITSI_INPUT_DOMAIN" ] && [ -n "$JITSI_DEFAULT_DOMAIN" ]; then
      JITSI_DOMAIN="$JITSI_DEFAULT_DOMAIN"
    elif [ -n "$JITSI_INPUT_DOMAIN" ]; then
      JITSI_DOMAIN="$JITSI_INPUT_DOMAIN"
    else
      __error "Domain name is required"
      exit $JITSI_EXIT_USAGE
    fi
    
    # Validate domain
    if ! __validate_domain "$JITSI_DOMAIN"; then
      __error "Invalid domain format: $JITSI_DOMAIN"
      exit $JITSI_EXIT_USAGE
    fi
  fi
  
  # Email configuration
  if [ -z "$JITSI_ADMIN_EMAIL" ]; then
    JITSI_DEFAULT_EMAIL="admin@$JITSI_DOMAIN"
    
    __input "Administrator email address" "$JITSI_DEFAULT_EMAIL"
    read JITSI_INPUT_EMAIL
    
    if [ -z "$JITSI_INPUT_EMAIL" ]; then
      JITSI_ADMIN_EMAIL="$JITSI_DEFAULT_EMAIL"
    else
      JITSI_ADMIN_EMAIL="$JITSI_INPUT_EMAIL"
    fi
    
    # Validate email
    if ! __validate_email "$JITSI_ADMIN_EMAIL"; then
      __error "Invalid email format: $JITSI_ADMIN_EMAIL"
      exit $JITSI_EXIT_USAGE
    fi
  fi
  
  # Organization name
  if [ -z "$JITSI_ORG_NAME" ] || [ "$JITSI_ORG_NAME" = "$JITSI_DEFAULT_ORG_NAME" ]; then
    __input "Organization name for branding" "$JITSI_DEFAULT_ORG_NAME"
    read JITSI_INPUT_ORG
    
    if [ -n "$JITSI_INPUT_ORG" ]; then
      JITSI_ORG_NAME="$JITSI_INPUT_ORG"
    fi
  fi
  
  # Update Keycloak admin user to use the domain
  JITSI_KEYCLOAK_ADMIN_USER="administrator@$JITSI_DOMAIN"
  
  # Generate all passwords
  __info "Generating secure passwords for services..."
  JITSI_MARIADB_ROOT_PASSWORD=`__generate_password`
  JITSI_MARIADB_PASSWORD=`__generate_password`
  JITSI_KEYCLOAK_DB_PASSWORD=`__generate_password`
  JITSI_KEYCLOAK_ADMIN_PASSWORD=`__generate_password`
  JITSI_JICOFO_AUTH_PASSWORD=`__generate_password`
  JITSI_JVB_AUTH_PASSWORD=`__generate_password`
  JITSI_JIBRI_XMPP_PASSWORD=`__generate_password`
  JITSI_JIBRI_RECORDER_PASSWORD=`__generate_password`
  JITSI_JWT_APP_SECRET=`__generate_password`
  JITSI_TURN_SECRET=`__generate_password`
  JITSI_GRAFANA_ADMIN_PASSWORD=`__generate_password`
  JITSI_UPTIME_KUMA_PASSWORD=`__generate_password`
  
  # Show configuration summary
  printf_newline_color "${JITSI_BOLD}" "\nConfiguration Summary:"
  printf_newline_nc "  Domain:       %s" "$JITSI_DOMAIN"
  printf_newline_nc "  Email:        %s" "$JITSI_ADMIN_EMAIL"
  printf_newline_nc "  Organization: %s" "$JITSI_ORG_NAME"
  printf_newline_nc "  Timezone:     %s" "$JITSI_TIMEZONE"
  
  printf_reset_color "$JITSI_PURPLE" "\n%sProceed with installation? [Y/n] " "$INPUT_PREFIX"
  read JITSI_CONFIRM
  
  case "$JITSI_CONFIRM" in
    [nN]|[nN][oO])
      __info "Installation cancelled by user"
      exit $JITSI_EXIT_SUCCESS
      ;;
  esac
}

__store_passwords() {
  __info "Storing passwords temporarily..."
  
  JITSI_PASSWORD_FILE="$JITSI_BASE_DIR/.passwords"
  
  cat > "$JITSI_PASSWORD_FILE" << EOF
# Jitsi Meet Enterprise - Service Credentials
# Generated: `date`
# Domain: $JITSI_DOMAIN
# 
# IMPORTANT: Save these credentials securely and delete this file!
# This file will be automatically deleted in 24 hours.

## Keycloak System Administration (Global Keycloak Admin)
URL: https://auth.$JITSI_DOMAIN/admin/
Username: administrator@$JITSI_DOMAIN
Password: $JITSI_KEYCLOAK_ADMIN_PASSWORD

## Jitsi Organization Administrator (Jitsi Meet Admin)
Username: administrator
Realm: jitsi (or your organization realm)
Note: This account will be created in the Jitsi realm for meeting administration

## Grafana Monitoring
URL: https://grafana.$JITSI_DOMAIN/
Username: admin
Password: $JITSI_GRAFANA_ADMIN_PASSWORD

## Uptime Kuma Monitoring
URL: https://uptime.$JITSI_DOMAIN/
Username: admin
Password: $JITSI_UPTIME_KUMA_PASSWORD

## MariaDB Database
Root Password: $JITSI_MARIADB_ROOT_PASSWORD
Jitsi User: jitsi
Jitsi Password: $JITSI_MARIADB_PASSWORD
Keycloak Password: $JITSI_KEYCLOAK_DB_PASSWORD

## Internal Service Passwords
JWT App Secret: $JITSI_JWT_APP_SECRET
Jicofo Auth: $JITSI_JICOFO_AUTH_PASSWORD
JVB Auth: $JITSI_JVB_AUTH_PASSWORD
TURN Secret: $JITSI_TURN_SECRET
Jibri XMPP: $JITSI_JIBRI_XMPP_PASSWORD
Jibri Recorder: $JITSI_JIBRI_RECORDER_PASSWORD
EOF
  
  chmod 600 "$JITSI_PASSWORD_FILE"
  chown root:root "$JITSI_PASSWORD_FILE"
  
  __warning "Passwords saved to: $JITSI_PASSWORD_FILE"
  __warning "IMPORTANT: Save these credentials and delete the file for security!"
}

# Section 13: Nginx Configuration Generator
__generate_nginx_vhost_template() {
  JITSI_VHOST_NAME="$1"
  JITSI_BACKEND_PORT="$2"
  JITSI_ADDITIONAL_CONFIG="${3:-}"
  
  cat << EOF
# Nginx configuration for $JITSI_VHOST_NAME
# Generated by Jitsi Meet Enterprise Installer

# HTTP to HTTPS redirect
server {
    listen 80;
    listen [::]:80;
    server_name $JITSI_VHOST_NAME;
    
    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }
    
    location / {
        return 301 https://\$server_name\$request_uri;
    }
}

# HTTPS server
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name $JITSI_VHOST_NAME;
    
    # SSL configuration
    ssl_certificate $JITSI_SSL_CERT_PATH;
    ssl_certificate_key $JITSI_SSL_KEY_PATH;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    
    # Gzip compression
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
    gzip_vary on;
    gzip_comp_level 6;
    
    # Logging
    access_log /var/log/nginx/${JITSI_VHOST_NAME}_access.log;
    error_log /var/log/nginx/${JITSI_VHOST_NAME}_error.log;
    
    # Health check endpoint
    location /healthz {
        access_log off;
        return 200 "OK";
        add_header Content-Type text/plain;
    }
    
    # Main location block
    location / {
        proxy_pass http://$JITSI_DOCKER_BRIDGE_IP:$JITSI_BACKEND_PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        # Buffer sizes
        proxy_buffer_size 4k;
        proxy_buffers 8 4k;
        proxy_busy_buffers_size 8k;
        
        # Additional service-specific configuration
        $JITSI_ADDITIONAL_CONFIG
    }
}
EOF
}

__generate_main_jitsi_config() {
  __info "Generating main Jitsi vhost configuration..."
  
  JITSI_MAIN_CONFIG=`cat << 'EOF'
        # Rate limiting
        limit_req_zone $binary_remote_addr zone=jitsi_auth:10m rate=5r/s;
        limit_req_zone $binary_remote_addr zone=jitsi_api:10m rate=20r/s;
        
        # Keycloak authentication endpoints
        location /auth/ {
            proxy_pass http://$JITSI_DOCKER_BRIDGE_IP:8080/auth/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            limit_req zone=jitsi_auth burst=10 nodelay;
        }
        
        location /admin/ {
            proxy_pass http://$JITSI_DOCKER_BRIDGE_IP:8080/admin/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            limit_req zone=jitsi_auth burst=5 nodelay;
        }
        
        # Public statistics endpoint
        location /stats/ {
            proxy_pass http://$JITSI_DOCKER_BRIDGE_IP:3002/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
        
        # API endpoints
        location /api/ {
            proxy_pass http://$JITSI_DOCKER_BRIDGE_IP:8000/api/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            limit_req zone=jitsi_api burst=20 nodelay;
        }
        
        # XMPP WebSocket
        location /xmpp-websocket {
            proxy_pass http://$JITSI_DOCKER_BRIDGE_IP:5280/xmpp-websocket;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $host;
            proxy_read_timeout 900s;
        }
        
        # BOSH endpoint
        location /http-bind {
            proxy_pass http://$JITSI_DOCKER_BRIDGE_IP:5280/http-bind;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
        
        # Colibri WebSocket
        location /colibri-ws/ {
            proxy_pass http://$JITSI_DOCKER_BRIDGE_IP:8000/colibri-ws/;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $host;
            proxy_read_timeout 900s;
        }
        
        # Static files caching
        location ~* \.(jpg|jpeg|png|gif|ico|css|js|woff|woff2|ttf|svg)$ {
            proxy_pass http://$JITSI_DOCKER_BRIDGE_IP:8000;
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
EOF
`
  
  printf "%s" "$JITSI_MAIN_CONFIG"
}

__generate_all_vhost_configs() {
  __header "Generating Nginx vHost Configurations"
  
  # Check for existing nginx configurations that might conflict
  __check_nginx_conflicts() {
    local domain="$1"
    local vhost_file="/etc/nginx/vhosts/${domain}.conf"
    
    if [ -f "$vhost_file" ]; then
      __warning "Existing nginx configuration found: $vhost_file"
      __info "Backing up existing configuration to ${vhost_file}.backup"
      mv "$vhost_file" "${vhost_file}.backup"
    fi
    
    # Check for default server configs that might intercept requests
    for conf in /etc/nginx/vhosts/*.conf; do
      if [ -f "$conf" ]; then
        if grep -q "default_server" "$conf" 2>/dev/null; then
          __warning "Found default_server in $conf - this may intercept requests"
          __info "Consider disabling: mv $conf ${conf}.disabled"
        fi
        # Check for configs without server_name that catch all requests
        if ! grep -q "server_name" "$conf" 2>/dev/null && grep -q "listen.*443" "$conf" 2>/dev/null; then
          __warning "Config $conf listens on 443 without server_name - may intercept requests"
          __info "Consider disabling: mv $conf ${conf}.disabled"
        fi
      fi
    done
  }
  
  # Check for conflicts before creating configs
  __check_nginx_conflicts "$JITSI_DOMAIN"
  
  # Main domain (comprehensive config)
  __info "Creating vhost: $JITSI_DOMAIN"
  __generate_nginx_vhost_template "$JITSI_DOMAIN" "8000" "`__generate_main_jitsi_config`" > "/etc/nginx/vhosts/$JITSI_DOMAIN.conf"
  
  # Meet subdomain (same as main)
  __info "Creating vhost: meet.$JITSI_DOMAIN"
  __generate_nginx_vhost_template "meet.$JITSI_DOMAIN" "8000" "`__generate_main_jitsi_config`" > "/etc/nginx/vhosts/meet.$JITSI_DOMAIN.conf"
  
  # Auth subdomain (Keycloak)
  __info "Creating vhost: auth.$JITSI_DOMAIN"
  __generate_nginx_vhost_template "auth.$JITSI_DOMAIN" "8080" "" > "/etc/nginx/vhosts/auth.$JITSI_DOMAIN.conf"
  
  # Admin subdomain (Keycloak admin)
  __info "Creating vhost: admin.$JITSI_DOMAIN"
  __generate_nginx_vhost_template "admin.$JITSI_DOMAIN" "8080" "" > "/etc/nginx/vhosts/admin.$JITSI_DOMAIN.conf"
  
  # Grafana subdomain
  __info "Creating vhost: grafana.$JITSI_DOMAIN"
  __generate_nginx_vhost_template "grafana.$JITSI_DOMAIN" "3000" "" > "/etc/nginx/vhosts/grafana.$JITSI_DOMAIN.conf"
  
  # Stats subdomain (Public Grafana)
  __info "Creating vhost: stats.$JITSI_DOMAIN"
  __generate_nginx_vhost_template "stats.$JITSI_DOMAIN" "3002" "" > "/etc/nginx/vhosts/stats.$JITSI_DOMAIN.conf"
  
  # Uptime subdomain
  __info "Creating vhost: uptime.$JITSI_DOMAIN"
  __generate_nginx_vhost_template "uptime.$JITSI_DOMAIN" "3001" "" > "/etc/nginx/vhosts/uptime.$JITSI_DOMAIN.conf"
  
  # Whiteboard subdomain (Excalidraw)
  __info "Creating vhost: whiteboard.$JITSI_DOMAIN"
  __generate_nginx_vhost_template "whiteboard.$JITSI_DOMAIN" "3003" "" > "/etc/nginx/vhosts/whiteboard.$JITSI_DOMAIN.conf"
  
  # Pad subdomain (Etherpad)
  __info "Creating vhost: pad.$JITSI_DOMAIN"
  __generate_nginx_vhost_template "pad.$JITSI_DOMAIN" "9001" "" > "/etc/nginx/vhosts/pad.$JITSI_DOMAIN.conf"
  
  # API subdomain
  __info "Creating vhost: api.$JITSI_DOMAIN"
  __generate_nginx_vhost_template "api.$JITSI_DOMAIN" "8000" "" > "/etc/nginx/vhosts/api.$JITSI_DOMAIN.conf"
  
  # Metrics subdomain (Prometheus)
  __info "Creating vhost: metrics.$JITSI_DOMAIN"
  __generate_nginx_vhost_template "metrics.$JITSI_DOMAIN" "9090" "" > "/etc/nginx/vhosts/metrics.$JITSI_DOMAIN.conf"
  
  # Trace subdomain (Jaeger)
  __info "Creating vhost: trace.$JITSI_DOMAIN"
  __generate_nginx_vhost_template "trace.$JITSI_DOMAIN" "16686" "" > "/etc/nginx/vhosts/trace.$JITSI_DOMAIN.conf"
  
  __success "All vhost configurations created"
}

__test_nginx_config() {
  __info "Testing nginx configuration..."
  
  if nginx -t >/dev/null 2>&1; then
    __success "Nginx configuration valid"
    
    __info "Reloading nginx..."
    systemctl reload nginx || __handle_error "Failed to reload nginx"
    __success "Nginx reloaded successfully"
  else
    __error "Nginx configuration test failed:"
    nginx -t 2>&1
    __handle_error "Invalid nginx configuration"
  fi
}

# Section 14: Container Management Functions
__manage_container() {
  JITSI_CONTAINER_NAME="$1"
  JITSI_CONTAINER_IMAGE="$2"
  JITSI_CONTAINER_ARGS="$3"
  
  __info "Managing container: $JITSI_CONTAINER_NAME"
  
  # Stop and remove existing container
  if docker ps -a --format '{{.Names}}' | grep -q "^${JITSI_CONTAINER_NAME}$"; then
    __progress "Stopping existing container..."
    docker stop "$JITSI_CONTAINER_NAME" >/dev/null 2>&1 || true
    docker rm "$JITSI_CONTAINER_NAME" >/dev/null 2>&1 || true
  fi
  
  # Create new container
  # Build the docker run command
  JITSI_DOCKER_CMD="docker run $JITSI_CONTAINER_ARGS"
  if [ "$JITSI_DEBUG_MODE" = "true" ]; then
    __info "Docker command: $JITSI_DOCKER_CMD"
  fi
  
  # Use spinner for container creation
  __spinner "Deploying $JITSI_CONTAINER_NAME" "$JITSI_DOCKER_CMD" || __handle_error "Failed to create container: $JITSI_CONTAINER_NAME"
}

__wait_for_container_health() {
  JITSI_WAIT_CONTAINER="$1"
  JITSI_WAIT_TIMEOUT="${2:-$JITSI_SERVICE_STARTUP_TIMEOUT}"
  JITSI_WAIT_START=`date +%s`
  
  __progress "Waiting for $JITSI_WAIT_CONTAINER to be healthy..."
  
  while true; do
    JITSI_CONTAINER_STATUS=`docker inspect -f '{{.State.Running}}' "$JITSI_WAIT_CONTAINER" 2>/dev/null || printf "false"`
    
    if [ "$JITSI_CONTAINER_STATUS" = "true" ]; then
      __success "$JITSI_WAIT_CONTAINER is running"
      return 0
    fi
    
    JITSI_WAIT_CURRENT=`date +%s`
    JITSI_WAIT_ELAPSED=`expr $JITSI_WAIT_CURRENT - $JITSI_WAIT_START`
    
    if [ $JITSI_WAIT_ELAPSED -gt $JITSI_WAIT_TIMEOUT ]; then
      __error "$JITSI_WAIT_CONTAINER failed to start within timeout"
      return 1
    fi
    
    if [ `expr $JITSI_WAIT_ELAPSED % 30` -eq 0 ]; then
      __info "Still waiting for $JITSI_WAIT_CONTAINER... ${JITSI_WAIT_ELAPSED}s elapsed"
    fi
    
    sleep 5
  done
}

__deploy_mariadb() {
  __header "Deploying MariaDB Database"
  
  JITSI_MARIADB_ARGS="-d \
    --name jitsi-mariadb \
    --restart always \
    --pull always \
    --log-driver $JITSI_DOCKER_LOG_DRIVER \
    --log-opt max-size=$JITSI_DOCKER_LOG_MAX_SIZE \
    --log-opt max-file=$JITSI_DOCKER_LOG_MAX_FILES \
    --network $JITSI_DOCKER_NETWORK_NAME \
    --memory $JITSI_CONTAINER_MEMORY_LIMIT \
    -e MYSQL_ROOT_PASSWORD=$JITSI_MARIADB_ROOT_PASSWORD \
    -e MYSQL_DATABASE=$JITSI_MARIADB_DATABASE \
    -e MYSQL_USER=$JITSI_MARIADB_USER \
    -e MYSQL_PASSWORD=$JITSI_MARIADB_PASSWORD \
    -e TZ=$JITSI_TIMEZONE \
    -v $JITSI_ROOTFS_DIR/db/mariadb:/var/lib/mysql \
    -v $JITSI_ROOTFS_DIR/config/mariadb:/etc/mysql/conf.d \
    mariadb:11.2"
  
  __manage_container "jitsi-mariadb" "mariadb:11.2" "$JITSI_MARIADB_ARGS"
  __wait_for_container_health "jitsi-mariadb"
  
  # Create Keycloak database
  __progress "Creating Keycloak database..."
  sleep 10  # Wait for MariaDB to fully initialize
  
  docker exec jitsi-mariadb mariadb -u root -p"$JITSI_MARIADB_ROOT_PASSWORD" -e "
    CREATE DATABASE IF NOT EXISTS keycloak;
    CREATE USER IF NOT EXISTS 'keycloak'@'%' IDENTIFIED BY '$JITSI_KEYCLOAK_DB_PASSWORD';
    GRANT ALL PRIVILEGES ON keycloak.* TO 'keycloak'@'%';
    FLUSH PRIVILEGES;
  " || __warning "Keycloak database may already exist"
}

__deploy_valkey() {
  __header "Deploying Valkey Cache"
  
  JITSI_VALKEY_ARGS="-d \
    --name jitsi-valkey \
    --restart always \
    --pull always \
    --log-driver $JITSI_DOCKER_LOG_DRIVER \
    --log-opt max-size=$JITSI_DOCKER_LOG_MAX_SIZE \
    --log-opt max-file=$JITSI_DOCKER_LOG_MAX_FILES \
    --network $JITSI_DOCKER_NETWORK_NAME \
    --memory 512m \
    -e TZ=$JITSI_TIMEZONE \
    -v $JITSI_ROOTFS_DIR/db/valkey:/data \
    -v $JITSI_ROOTFS_DIR/config/valkey:/usr/local/etc/valkey \
    valkey/valkey:7.2-alpine"
  
  __manage_container "jitsi-valkey" "valkey/valkey:7.2-alpine" "$JITSI_VALKEY_ARGS"
  __wait_for_container_health "jitsi-valkey"
}

__deploy_keycloak() {
  __header "Deploying Keycloak Authentication"
  
  JITSI_KEYCLOAK_ARGS="-d \
    --name jitsi-keycloak \
    --restart always \
    --pull always \
    --log-driver $JITSI_DOCKER_LOG_DRIVER \
    --log-opt max-size=$JITSI_DOCKER_LOG_MAX_SIZE \
    --log-opt max-file=$JITSI_DOCKER_LOG_MAX_FILES \
    --network $JITSI_DOCKER_NETWORK_NAME \
    --memory $JITSI_CONTAINER_MEMORY_LIMIT \
    -e KC_DB=mariadb \
    -e KC_DB_URL=jdbc:mariadb://jitsi-mariadb:3306/keycloak \
    -e KC_DB_USERNAME=keycloak \
    -e KC_DB_PASSWORD=$JITSI_KEYCLOAK_DB_PASSWORD \
    -e KEYCLOAK_ADMIN=administrator@$JITSI_DOMAIN \
    -e KEYCLOAK_ADMIN_PASSWORD=$JITSI_KEYCLOAK_ADMIN_PASSWORD \
    -e KC_PROXY=edge \
    -e KC_HOSTNAME_STRICT=false \
    -e KC_HTTP_ENABLED=true \
    -e TZ=$JITSI_TIMEZONE \
    -v $JITSI_ROOTFS_DIR/data/keycloak:/opt/keycloak/data \
    -v $JITSI_ROOTFS_DIR/config/keycloak:/opt/keycloak/conf \
    quay.io/keycloak/keycloak:24.0 \
    start-dev"
  
  __manage_container "jitsi-keycloak" "quay.io/keycloak/keycloak:24.0" "$JITSI_KEYCLOAK_ARGS"
  __wait_for_container_health "jitsi-keycloak"
}

__deploy_jitsi_server() {
  __header "Deploying Jitsi Web Server"
  
  JITSI_SERVER_ARGS="-d \
    --name jitsi-server \
    --restart always \
    --pull always \
    --log-driver $JITSI_DOCKER_LOG_DRIVER \
    --log-opt max-size=$JITSI_DOCKER_LOG_MAX_SIZE \
    --log-opt max-file=$JITSI_DOCKER_LOG_MAX_FILES \
    --network $JITSI_DOCKER_NETWORK_NAME \
    --memory $JITSI_CONTAINER_MEMORY_LIMIT \
    -e PUBLIC_URL=https://$JITSI_DOMAIN/ \
    -e XMPP_SERVER=jitsi-prosody \
    -e XMPP_DOMAIN=$JITSI_DOMAIN \
    -e XMPP_AUTH_DOMAIN=auth.$JITSI_DOMAIN \
    -e XMPP_INTERNAL_MUC_DOMAIN=internal-muc.$JITSI_DOMAIN \
    -e XMPP_MUC_DOMAIN=muc.$JITSI_DOMAIN \
    -e XMPP_GUEST_DOMAIN=guest.$JITSI_DOMAIN \
    -e XMPP_BOSH_URL_BASE=http://jitsi-prosody:5280 \
    -e JICOFO_AUTH_USER=focus \
    -e JICOFO_AUTH_PASSWORD=$JITSI_JICOFO_AUTH_PASSWORD \
    -e JVB_AUTH_USER=jvb \
    -e JVB_AUTH_PASSWORD=$JITSI_JVB_AUTH_PASSWORD \
    -e ENABLE_AUTH=1 \
    -e ENABLE_GUESTS=1 \
    -e ENABLE_LETSENCRYPT=0 \
    -e ENABLE_HTTP_REDIRECT=0 \
    -e ENABLE_RECORDING=1 \
    -e ENABLE_TRANSCRIPTIONS=1 \
    -e ENABLE_ETHERPAD=1 \
    -e ETHERPAD_URL_BASE=https://pad.$JITSI_DOMAIN \
    -e ENABLE_LOBBY=1 \
    -e ENABLE_XMPP_WEBSOCKET=1 \
    -e ENABLE_COLIBRI_WEBSOCKET=1 \
    -e ENABLE_JAAS_COMPONENTS=0 \
    -e JWT_APP_ID=$JITSI_DOMAIN \
    -e JWT_APP_SECRET=$JITSI_JWT_APP_SECRET \
    -e JWT_ACCEPTED_ISSUERS=$JITSI_DOMAIN \
    -e JWT_ACCEPTED_AUDIENCES=$JITSI_DOMAIN \
    -e ENABLE_SIMULCAST=1 \
    -e ENABLE_REMB=1 \
    -e ENABLE_TCC=1 \
    -e TZ=$JITSI_TIMEZONE \
    -v $JITSI_ROOTFS_DIR/config/jitsi:/config \
    -v $JITSI_ROOTFS_DIR/data/jitsi:/usr/share/jitsi-meet \
    -v $JITSI_ROOTFS_DIR/data/transcripts:/usr/share/jitsi-meet/transcripts \
    jitsi/web:stable"
  
  __manage_container "jitsi-server" "jitsi/web:stable" "$JITSI_SERVER_ARGS"
  __wait_for_container_health "jitsi-server"
}

__deploy_prosody() {
  __header "Deploying Prosody XMPP Server"
  
  JITSI_PROSODY_ARGS="-d \
    --name jitsi-prosody \
    --restart always \
    --pull always \
    --log-driver $JITSI_DOCKER_LOG_DRIVER \
    --log-opt max-size=$JITSI_DOCKER_LOG_MAX_SIZE \
    --log-opt max-file=$JITSI_DOCKER_LOG_MAX_FILES \
    --network $JITSI_DOCKER_NETWORK_NAME \
    --memory $JITSI_CONTAINER_MEMORY_LIMIT \
    -p 5222:5222 \
    -p 5269:5269 \
    -p 5347:5347 \
    -e XMPP_DOMAIN=$JITSI_DOMAIN \
    -e XMPP_AUTH_DOMAIN=auth.$JITSI_DOMAIN \
    -e XMPP_GUEST_DOMAIN=guest.$JITSI_DOMAIN \
    -e XMPP_MUC_DOMAIN=muc.$JITSI_DOMAIN \
    -e XMPP_INTERNAL_MUC_DOMAIN=internal-muc.$JITSI_DOMAIN \
    -e XMPP_MODULES='' \
    -e XMPP_MUC_MODULES='' \
    -e XMPP_INTERNAL_MUC_MODULES='' \
    -e JICOFO_COMPONENT_SECRET=$JITSI_JICOFO_AUTH_PASSWORD \
    -e JICOFO_AUTH_USER=focus \
    -e JICOFO_AUTH_PASSWORD=$JITSI_JICOFO_AUTH_PASSWORD \
    -e JVB_AUTH_USER=jvb \
    -e JVB_AUTH_PASSWORD=$JITSI_JVB_AUTH_PASSWORD \
    -e JIBRI_XMPP_USER=jibri \
    -e JIBRI_XMPP_PASSWORD=$JITSI_JIBRI_XMPP_PASSWORD \
    -e JIBRI_RECORDER_USER=recorder \
    -e JIBRI_RECORDER_PASSWORD=$JITSI_JIBRI_RECORDER_PASSWORD \
    -e JWT_APP_ID=$JITSI_DOMAIN \
    -e JWT_APP_SECRET=$JITSI_JWT_APP_SECRET \
    -e JWT_ACCEPTED_ISSUERS=$JITSI_DOMAIN \
    -e JWT_ACCEPTED_AUDIENCES=$JITSI_DOMAIN \
    -e JWT_ASAP_KEYSERVER='' \
    -e JWT_ALLOW_EMPTY=0 \
    -e JWT_AUTH_TYPE=jwt \
    -e JWT_TOKEN_AUTH_MODULE=token_verification \
    -e ENABLE_AUTH=1 \
    -e ENABLE_GUESTS=1 \
    -e ENABLE_LOBBY=1 \
    -e ENABLE_XMPP_WEBSOCKET=1 \
    -e PUBLIC_URL=https://$JITSI_DOMAIN/ \
    -e TZ=$JITSI_TIMEZONE \
    -v $JITSI_ROOTFS_DIR/config/prosody:/config \
    -v $JITSI_ROOTFS_DIR/data/prosody:/var/lib/prosody \
    jitsi/prosody:stable"
  
  __manage_container "jitsi-prosody" "jitsi/prosody:stable" "$JITSI_PROSODY_ARGS"
  __wait_for_container_health "jitsi-prosody"
}

__deploy_jicofo() {
  __header "Deploying Jicofo Conference Focus"
  
  JITSI_JICOFO_ARGS="-d \
    --name jitsi-jicofo \
    --restart always \
    --pull always \
    --log-driver $JITSI_DOCKER_LOG_DRIVER \
    --log-opt max-size=$JITSI_DOCKER_LOG_MAX_SIZE \
    --log-opt max-file=$JITSI_DOCKER_LOG_MAX_FILES \
    --network $JITSI_DOCKER_NETWORK_NAME \
    --memory $JITSI_CONTAINER_MEMORY_LIMIT \
    -e XMPP_SERVER=jitsi-prosody \
    -e XMPP_DOMAIN=$JITSI_DOMAIN \
    -e XMPP_AUTH_DOMAIN=auth.$JITSI_DOMAIN \
    -e XMPP_INTERNAL_MUC_DOMAIN=internal-muc.$JITSI_DOMAIN \
    -e XMPP_MUC_DOMAIN=muc.$JITSI_DOMAIN \
    -e JICOFO_COMPONENT_SECRET=$JITSI_JICOFO_AUTH_PASSWORD \
    -e JICOFO_AUTH_USER=focus \
    -e JICOFO_AUTH_PASSWORD=$JITSI_JICOFO_AUTH_PASSWORD \
    -e JICOFO_ENABLE_AUTH=true \
    -e TZ=$JITSI_TIMEZONE \
    -v $JITSI_ROOTFS_DIR/config/jicofo:/config \
    -v $JITSI_ROOTFS_DIR/data/jicofo:/tmp/jicofo \
    jitsi/jicofo:stable"
  
  __manage_container "jitsi-jicofo" "jitsi/jicofo:stable" "$JITSI_JICOFO_ARGS"
  __wait_for_container_health "jitsi-jicofo"
}

__deploy_jvb() {
  __header "Deploying JVB Videobridge"
  
  JITSI_JVB_ARGS="-d \
    --name jitsi-jvb \
    --restart always \
    --pull always \
    --log-driver $JITSI_DOCKER_LOG_DRIVER \
    --log-opt max-size=$JITSI_DOCKER_LOG_MAX_SIZE \
    --log-opt max-file=$JITSI_DOCKER_LOG_MAX_FILES \
    --network host \
    --memory $JITSI_CONTAINER_MEMORY_LIMIT \
    --shm-size $JITSI_SHARED_MEMORY_SIZE \
    -e XMPP_SERVER=localhost \
    -e XMPP_DOMAIN=$JITSI_DOMAIN \
    -e XMPP_AUTH_DOMAIN=auth.$JITSI_DOMAIN \
    -e XMPP_INTERNAL_MUC_DOMAIN=internal-muc.$JITSI_DOMAIN \
    -e JVB_AUTH_USER=jvb \
    -e JVB_AUTH_PASSWORD=$JITSI_JVB_AUTH_PASSWORD \
    -e JVB_BREWERY_MUC=jvbbrewery \
    -e JVB_PORT=10000 \
    -e JVB_TCP_HARVESTER_DISABLED=true \
    -e JVB_TCP_PORT=4443 \
    -e JVB_TCP_MAPPED_PORT=4443 \
    -e JVB_ENABLE_APIS=rest,colibri \
    -e ENABLE_STATISTICS=true \
    -e ENABLE_COLIBRI_WEBSOCKET=true \
    -e TZ=$JITSI_TIMEZONE \
    -v $JITSI_ROOTFS_DIR/config/jvb:/config \
    -v $JITSI_ROOTFS_DIR/data/jvb:/tmp/jvb \
    jitsi/jvb:stable"
  
  __manage_container "jitsi-jvb" "jitsi/jvb:stable" "$JITSI_JVB_ARGS"
  __wait_for_container_health "jitsi-jvb"
}

__deploy_supporting_services() {
  # Deploy Etherpad
  __header "Deploying Etherpad"
  
  JITSI_ETHERPAD_ARGS="-d \
    --name jitsi-etherpad \
    --restart always \
    --pull always \
    --log-driver $JITSI_DOCKER_LOG_DRIVER \
    --log-opt max-size=$JITSI_DOCKER_LOG_MAX_SIZE \
    --log-opt max-file=$JITSI_DOCKER_LOG_MAX_FILES \
    --network $JITSI_DOCKER_NETWORK_NAME \
    --memory $JITSI_CONTAINER_MEMORY_LIMIT \
    -e DB_TYPE=mysql \
    -e DB_HOST=jitsi-mariadb \
    -e DB_PORT=3306 \
    -e DB_NAME=etherpad \
    -e DB_USER=etherpad \
    -e DB_PASS=$JITSI_MARIADB_PASSWORD \
    -e TRUST_PROXY=true \
    -e TZ=$JITSI_TIMEZONE \
    -v $JITSI_ROOTFS_DIR/data/etherpad:/opt/etherpad-lite/var \
    etherpad/etherpad:1.9.7"
  
  __manage_container "jitsi-etherpad" "etherpad/etherpad:1.9.7" "$JITSI_ETHERPAD_ARGS"
  
  # Deploy Excalidraw
  __header "Deploying Excalidraw Whiteboard"
  
  JITSI_EXCALIDRAW_ARGS="-d \
    --name jitsi-excalidraw \
    --restart always \
    --pull always \
    --log-driver $JITSI_DOCKER_LOG_DRIVER \
    --log-opt max-size=$JITSI_DOCKER_LOG_MAX_SIZE \
    --log-opt max-file=$JITSI_DOCKER_LOG_MAX_FILES \
    --network $JITSI_DOCKER_NETWORK_NAME \
    --memory $JITSI_CONTAINER_MEMORY_LIMIT \
    -e TZ=$JITSI_TIMEZONE \
    -v $JITSI_ROOTFS_DIR/data/excalidraw:/data \
    excalidraw/excalidraw:latest"
  
  __manage_container "jitsi-excalidraw" "excalidraw/excalidraw:latest" "$JITSI_EXCALIDRAW_ARGS"
  
  # Deploy Prometheus
  __header "Deploying Prometheus Metrics"
  
  JITSI_PROMETHEUS_ARGS="-d \
    --name jitsi-prometheus \
    --restart always \
    --pull always \
    --log-driver $JITSI_DOCKER_LOG_DRIVER \
    --log-opt max-size=$JITSI_DOCKER_LOG_MAX_SIZE \
    --log-opt max-file=$JITSI_DOCKER_LOG_MAX_FILES \
    --network $JITSI_DOCKER_NETWORK_NAME \
    --memory 512m \
    -e TZ=$JITSI_TIMEZONE \
    -v $JITSI_ROOTFS_DIR/config/prometheus:/etc/prometheus \
    -v $JITSI_ROOTFS_DIR/data/prometheus:/prometheus \
    prom/prometheus:v2.45.0"
  
  __manage_container "jitsi-prometheus" "prom/prometheus:v2.45.0" "$JITSI_PROMETHEUS_ARGS"
  
  # Deploy Grafana (Authenticated)
  __header "Deploying Grafana Dashboard"
  
  JITSI_GRAFANA_ARGS="-d \
    --name jitsi-grafana \
    --restart always \
    --pull always \
    --log-driver $JITSI_DOCKER_LOG_DRIVER \
    --log-opt max-size=$JITSI_DOCKER_LOG_MAX_SIZE \
    --log-opt max-file=$JITSI_DOCKER_LOG_MAX_FILES \
    --network $JITSI_DOCKER_NETWORK_NAME \
    --memory $JITSI_CONTAINER_MEMORY_LIMIT \
    -e GF_SECURITY_ADMIN_PASSWORD=$JITSI_GRAFANA_ADMIN_PASSWORD \
    -e GF_USERS_ALLOW_SIGN_UP=false \
    -e GF_AUTH_ANONYMOUS_ENABLED=false \
    -e GF_SMTP_ENABLED=true \
    -e \"GF_SMTP_HOST=$JITSI_SMTP_HOST:$JITSI_SMTP_PORT\" \
    -e \"GF_SMTP_FROM_ADDRESS=no-reply@$JITSI_DOMAIN\" \
    -e \"GF_SMTP_FROM_NAME=$JITSI_ORG_NAME\" \
    -e \"TZ=$JITSI_TIMEZONE\" \
    -v $JITSI_ROOTFS_DIR/data/grafana:/var/lib/grafana \
    -v $JITSI_ROOTFS_DIR/config/grafana:/etc/grafana \
    grafana/grafana:10.0.0"
  
  __manage_container "jitsi-grafana" "grafana/grafana:10.0.0" "$JITSI_GRAFANA_ARGS"
  
  # Deploy Grafana Public (Anonymous)
  __header "Deploying Public Statistics Dashboard"
  
  JITSI_GRAFANA_PUBLIC_ARGS="-d \
    --name jitsi-grafana-public \
    --restart always \
    --pull always \
    --log-driver $JITSI_DOCKER_LOG_DRIVER \
    --log-opt max-size=$JITSI_DOCKER_LOG_MAX_SIZE \
    --log-opt max-file=$JITSI_DOCKER_LOG_MAX_FILES \
    --network $JITSI_DOCKER_NETWORK_NAME \
    --memory 512m \
    -e GF_AUTH_ANONYMOUS_ENABLED=true \
    -e GF_AUTH_ANONYMOUS_ORG_NAME=Public \
    -e GF_AUTH_ANONYMOUS_ORG_ROLE=Viewer \
    -e GF_USERS_ALLOW_SIGN_UP=false \
    -e GF_USERS_ALLOW_ORG_CREATE=false \
    -e GF_AUTH_DISABLE_LOGIN_FORM=true \
    -e TZ=$JITSI_TIMEZONE \
    -p 3002:3000 \
    -v $JITSI_ROOTFS_DIR/data/grafana-public:/var/lib/grafana \
    -v $JITSI_ROOTFS_DIR/config/grafana-public:/etc/grafana \
    grafana/grafana:10.0.0"
  
  __manage_container "jitsi-grafana-public" "grafana/grafana:10.0.0" "$JITSI_GRAFANA_PUBLIC_ARGS"
  
  # Deploy Jaeger
  __header "Deploying Jaeger Tracing"
  
  JITSI_JAEGER_ARGS="-d \
    --name jitsi-jaeger \
    --restart always \
    --pull always \
    --log-driver $JITSI_DOCKER_LOG_DRIVER \
    --log-opt max-size=$JITSI_DOCKER_LOG_MAX_SIZE \
    --log-opt max-file=$JITSI_DOCKER_LOG_MAX_FILES \
    --network $JITSI_DOCKER_NETWORK_NAME \
    --memory $JITSI_CONTAINER_MEMORY_LIMIT \
    -e COLLECTOR_ZIPKIN_HOST_PORT=:9411 \
    -e TZ=$JITSI_TIMEZONE \
    -v $JITSI_ROOTFS_DIR/data/jaeger:/tmp \
    jaegertracing/all-in-one:1.47"
  
  __manage_container "jitsi-jaeger" "jaegertracing/all-in-one:1.47" "$JITSI_JAEGER_ARGS"
  
  # Deploy Uptime Kuma
  __header "Deploying Uptime Kuma Monitoring"
  
  JITSI_UPTIME_KUMA_ARGS="-d \
    --name jitsi-uptime-kuma \
    --restart always \
    --pull always \
    --log-driver $JITSI_DOCKER_LOG_DRIVER \
    --log-opt max-size=$JITSI_DOCKER_LOG_MAX_SIZE \
    --log-opt max-file=$JITSI_DOCKER_LOG_MAX_FILES \
    --network $JITSI_DOCKER_NETWORK_NAME \
    --memory $JITSI_CONTAINER_MEMORY_LIMIT \
    -e TZ=$JITSI_TIMEZONE \
    -v $JITSI_ROOTFS_DIR/data/uptime-kuma:/app/data \
    louislam/uptime-kuma:1"
  
  __manage_container "jitsi-uptime-kuma" "louislam/uptime-kuma:1" "$JITSI_UPTIME_KUMA_ARGS"
  
  __success "All supporting services deployed"
}

# Section 15: Helper Script Generation
__generate_helper_scripts() {
  __header "Generating Helper Scripts"
  
  JITSI_SCRIPT_VERSION="$VERSION"
  JITSI_CREATION_DATE=`date '+%A, %b %d, %Y %I:%M %p %Z'`
  
  # Create jitsi-room-cleanup script
  __info "Creating room cleanup script..."
  cat > "/usr/local/bin/jitsi-room-cleanup" << 'EOF'
#!/bin/sh
# shellcheck shell=sh
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
##@Version           :  SCRIPT_VERSION
# @@Author           :  Jason Hempstead
# @@Contact          :  jason@casjaysdev.pro
# @@License          :  WTFPL
# @@ReadME           :  jitsi-room-cleanup --help
# @@Copyright        :  Copyright: (c) 2025 Jason Hempstead, Casjays Developments
# @@Created          :  CREATION_DATE
# @@File             :  jitsi-room-cleanup
# @@Description      :  Automated room cleanup for Jitsi Meet
# @@Changelog        :  New File
# @@TODO             :  Better documentation
# @@Other            :  
# @@Resource         :  
# @@Terminal App     :  no
# @@sudo/root        :  yes
# @@Template         :  shell/system
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Load configuration
. /opt/jitsi/.env 2>/dev/null || exit 1

# Configuration
CLEANUP_INTERVAL="${JITSI_ROOM_CLEANUP_INTERVAL:-604800}"
LOG_FILE="/var/log/casjaysdev/jitsi/cron/room-cleanup.log"

# Functions
log_message() {
  printf "[%s] %s\n" "`date '+%Y-%m-%d %H:%M:%S'`" "$1" >> "$LOG_FILE"
}

cleanup_prosody_rooms() {
  log_message "Starting Prosody room cleanup..."
  
  docker exec jitsi-prosody prosodyctl mod_muc_clear_history_interval "$CLEANUP_INTERVAL" || {
    log_message "ERROR: Failed to cleanup Prosody rooms"
    return 1
  }
  
  log_message "Prosody room cleanup completed"
}

cleanup_database_rooms() {
  log_message "Starting database room cleanup..."
  
  docker exec jitsi-mariadb mariadb -u root -p"$JITSI_MARIADB_ROOT_PASSWORD" jitsi -e "
    DELETE FROM room_history WHERE created_at < DATE_SUB(NOW(), INTERVAL 7 DAY);
    OPTIMIZE TABLE room_history;
  " || {
    log_message "ERROR: Failed to cleanup database rooms"
    return 1
  }
  
  log_message "Database room cleanup completed"
}

# Main
main() {
  log_message "Room cleanup started"
  
  cleanup_prosody_rooms
  cleanup_database_rooms
  
  log_message "Room cleanup completed"
}

# Execute
main "$@"
EOF
  
  # Replace placeholders
  sed -i "s/SCRIPT_VERSION/$JITSI_SCRIPT_VERSION/g" /usr/local/bin/jitsi-room-cleanup
  sed -i "s/CREATION_DATE/$JITSI_CREATION_DATE/g" /usr/local/bin/jitsi-room-cleanup
  chmod 755 /usr/local/bin/jitsi-room-cleanup
  
  # Create jitsi-db-optimize script
  __info "Creating database optimization script..."
  cat > "/usr/local/bin/jitsi-db-optimize" << 'EOF'
#!/bin/sh
# shellcheck shell=sh
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
##@Version           :  SCRIPT_VERSION
# @@Author           :  Jason Hempstead
# @@Contact          :  jason@casjaysdev.pro
# @@License          :  WTFPL
# @@ReadME           :  jitsi-db-optimize --help
# @@Copyright        :  Copyright: (c) 2025 Jason Hempstead, Casjays Developments
# @@Created          :  CREATION_DATE
# @@File             :  jitsi-db-optimize
# @@Description      :  Database optimization for Jitsi Meet
# @@Changelog        :  New File
# @@TODO             :  Better documentation
# @@Other            :  
# @@Resource         :  
# @@Terminal App     :  no
# @@sudo/root        :  yes
# @@Template         :  shell/system
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Load configuration
. /opt/jitsi/.env 2>/dev/null || exit 1

# Configuration
LOG_FILE="/var/log/casjaysdev/jitsi/cron/db-optimize.log"

# Functions
log_message() {
  printf "[%s] %s\n" "`date '+%Y-%m-%d %H:%M:%S'`" "$1" >> "$LOG_FILE"
}

optimize_mariadb() {
  log_message "Starting MariaDB optimization..."
  
  docker exec jitsi-mariadb mariadb-check -u root -p"$JITSI_MARIADB_ROOT_PASSWORD" --optimize --all-databases || {
    log_message "ERROR: Failed to optimize MariaDB"
    return 1
  }
  
  log_message "MariaDB optimization completed"
}

optimize_valkey() {
  log_message "Starting Valkey optimization..."
  
  docker exec jitsi-valkey valkey-cli FLUSHEXPIRED || {
    log_message "ERROR: Failed to optimize Valkey"
    return 1
  }
  
  log_message "Valkey optimization completed"
}

# Main
main() {
  log_message "Database optimization started"
  
  optimize_mariadb
  optimize_valkey
  
  log_message "Database optimization completed"
}

# Execute
main "$@"
EOF
  
  # Replace placeholders
  sed -i "s/SCRIPT_VERSION/$JITSI_SCRIPT_VERSION/g" /usr/local/bin/jitsi-db-optimize
  sed -i "s/CREATION_DATE/$JITSI_CREATION_DATE/g" /usr/local/bin/jitsi-db-optimize
  chmod 755 /usr/local/bin/jitsi-db-optimize
  
  # Create jitsi-health-check script
  __info "Creating health check script..."
  cat > "/usr/local/bin/jitsi-health-check" << 'EOF'
#!/bin/sh
# shellcheck shell=sh
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
##@Version           :  SCRIPT_VERSION
# @@Author           :  Jason Hempstead
# @@Contact          :  jason@casjaysdev.pro
# @@License          :  WTFPL
# @@ReadME           :  jitsi-health-check --help
# @@Copyright        :  Copyright: (c) 2025 Jason Hempstead, Casjays Developments
# @@Created          :  CREATION_DATE
# @@File             :  jitsi-health-check
# @@Description      :  Health monitoring for Jitsi Meet services
# @@Changelog        :  New File
# @@TODO             :  Better documentation
# @@Other            :  
# @@Resource         :  
# @@Terminal App     :  no
# @@sudo/root        :  yes
# @@Template         :  shell/system
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Load configuration
. /opt/jitsi/.env 2>/dev/null || exit 1

# Configuration
LOG_FILE="/var/log/casjaysdev/jitsi/cron/health-check.log"
CONTAINERS="mariadb valkey keycloak server prosody jicofo jvb etherpad excalidraw prometheus grafana grafana-public jaeger uptime-kuma"

# Functions
log_message() {
  LEVEL="$1"
  MESSAGE="$2"
  printf "[%s] [%s] %s\n" "`date '+%Y-%m-%d %H:%M:%S'`" "$LEVEL" "$MESSAGE" >> "$LOG_FILE"
}

check_container_health() {
  CONTAINER="jitsi-$1"
  
  if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
    if docker inspect -f '{{.State.Running}}' "$CONTAINER" 2>/dev/null | grep -q "true"; then
      log_message "OK" "$CONTAINER is running"
      return 0
    else
      log_message "ERROR" "$CONTAINER is not running"
      return 1
    fi
  else
    log_message "ERROR" "$CONTAINER not found"
    return 1
  fi
}

check_service_endpoint() {
  SERVICE="$1"
  URL="$2"
  
  if curl -s -o /dev/null -w "%{http_code}" "$URL" | grep -q "200"; then
    log_message "OK" "$SERVICE endpoint is healthy"
    return 0
  else
    log_message "WARNING" "$SERVICE endpoint returned non-200 status"
    return 1
  fi
}

# Main
main() {
  log_message "INFO" "Health check started"
  
  # Check containers
  for container in $CONTAINERS; do
    check_container_health "$container"
  done
  
  # Check service endpoints
  check_service_endpoint "Main" "https://$JITSI_DOMAIN/healthz"
  check_service_endpoint "Keycloak" "https://auth.$JITSI_DOMAIN/healthz"
  
  log_message "INFO" "Health check completed"
}

# Execute
main "$@"
EOF
  
  # Replace placeholders
  sed -i "s/SCRIPT_VERSION/$JITSI_SCRIPT_VERSION/g" /usr/local/bin/jitsi-health-check
  sed -i "s/CREATION_DATE/$JITSI_CREATION_DATE/g" /usr/local/bin/jitsi-health-check
  chmod 755 /usr/local/bin/jitsi-health-check
  
  # Create jitsi-backup-daily script
  __info "Creating backup script..."
  cat > "/usr/local/bin/jitsi-backup-daily" << 'EOF'
#!/bin/sh
# shellcheck shell=sh
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
##@Version           :  SCRIPT_VERSION
# @@Author           :  Jason Hempstead
# @@Contact          :  jason@casjaysdev.pro
# @@License          :  WTFPL
# @@ReadME           :  jitsi-backup-daily --help
# @@Copyright        :  Copyright: (c) 2025 Jason Hempstead, Casjays Developments
# @@Created          :  CREATION_DATE
# @@File             :  jitsi-backup-daily
# @@Description      :  Daily backup for Jitsi Meet
# @@Changelog        :  New File
# @@TODO             :  Better documentation
# @@Other            :  
# @@Resource         :  
# @@Terminal App     :  no
# @@sudo/root        :  yes
# @@Template         :  shell/system
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Load configuration
. /opt/jitsi/.env 2>/dev/null || exit 1

# Configuration
LOG_FILE="/var/log/casjaysdev/jitsi/cron/backup.log"
BACKUP_TYPE="${1:-daily}"
TIMESTAMP=`date +%Y%m%d_%H%M%S`

# Functions
log_message() {
  printf "[%s] %s\n" "`date '+%Y-%m-%d %H:%M:%S'`" "$1" >> "$LOG_FILE"
}

create_backup_dirs() {
  for dir in daily weekly monthly; do
    mkdir -p "$JITSI_BACKUP_DIR/$dir" || {
      log_message "ERROR: Failed to create backup directory: $dir"
      return 1
    }
  done
}

backup_database() {
  log_message "Starting database backup..."
  
  docker exec jitsi-mariadb mariadb-dump -u root -p"$JITSI_MARIADB_ROOT_PASSWORD" --all-databases > "$JITSI_BACKUP_DIR/mysql_dump_$TIMESTAMP.sql" || {
    log_message "ERROR: Failed to backup database"
    return 1
  }
  
  log_message "Database backup completed"
}

create_backup() {
  BACKUP_FILE="$JITSI_BACKUP_DIR/$BACKUP_TYPE/jitsi_backup_${BACKUP_TYPE}_$TIMESTAMP.tar.gz"
  
  log_message "Creating $BACKUP_TYPE backup: $BACKUP_FILE"
  
  tar -czf "$BACKUP_FILE" \
    "$JITSI_BASE_DIR/.env" \
    "$JITSI_BASE_DIR/.passwords" \
    "$JITSI_ROOTFS_DIR/config" \
    "$JITSI_ROOTFS_DIR/data" \
    "$JITSI_BACKUP_DIR/mysql_dump_$TIMESTAMP.sql" \
    2>/dev/null || {
    log_message "ERROR: Failed to create backup archive"
    return 1
  }
  
  # Remove temporary database dump
  rm -f "$JITSI_BACKUP_DIR/mysql_dump_$TIMESTAMP.sql"
  
  log_message "Backup created successfully: $BACKUP_FILE"
}

cleanup_old_backups() {
  case "$BACKUP_TYPE" in
    daily)
      find "$JITSI_BACKUP_DIR/daily" -name "*.tar.gz" -mtime +6 -delete
      log_message "Cleaned up daily backups older than 6 days"
      ;;
    weekly)
      find "$JITSI_BACKUP_DIR/weekly" -name "*.tar.gz" -mtime +21 -delete
      log_message "Cleaned up weekly backups older than 3 weeks"
      ;;
    monthly)
      find "$JITSI_BACKUP_DIR/monthly" -name "*.tar.gz" -mtime +60 -delete
      log_message "Cleaned up monthly backups older than 2 months"
      ;;
  esac
}

# Main
main() {
  log_message "Backup process started ($BACKUP_TYPE)"
  
  create_backup_dirs
  backup_database
  create_backup
  cleanup_old_backups
  
  log_message "Backup process completed"
}

# Execute
main "$@"
EOF
  
  # Replace placeholders
  sed -i "s/SCRIPT_VERSION/$JITSI_SCRIPT_VERSION/g" /usr/local/bin/jitsi-backup-daily
  sed -i "s/CREATION_DATE/$JITSI_CREATION_DATE/g" /usr/local/bin/jitsi-backup-daily
  chmod 755 /usr/local/bin/jitsi-backup-daily
  
  # Create jitsi-diagnose script
  __info "Creating diagnostic script..."
  cat > "/usr/local/bin/jitsi-diagnose" << 'EOF'
#!/bin/sh
# shellcheck shell=sh
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
##@Version           :  SCRIPT_VERSION
# @@Author           :  Jason Hempstead
# @@Contact          :  jason@casjaysdev.pro
# @@License          :  WTFPL
# @@ReadME           :  jitsi-diagnose --help
# @@Copyright        :  Copyright: (c) 2025 Jason Hempstead, Casjays Developments
# @@Created          :  CREATION_DATE
# @@File             :  jitsi-diagnose
# @@Description      :  Diagnostic tool for Jitsi Meet troubleshooting
# @@Changelog        :  New File
# @@TODO             :  Better documentation
# @@Other            :  
# @@Resource         :  
# @@Terminal App     :  yes
# @@sudo/root        :  yes
# @@Template         :  shell/system
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Load configuration
. /opt/jitsi/.env 2>/dev/null || exit 1

# Functions
print_header() {
  printf "\n=== %s ===\n" "$1"
}

check_system_resources() {
  print_header "System Resources"
  
  printf "Memory Usage:\n"
  free -h
  
  printf "\nCPU Load:\n"
  uptime
  
  printf "\nDisk Usage:\n"
  df -h | grep -E "^/|Filesystem"
}

check_containers() {
  print_header "Container Status"
  
  docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep jitsi
}

check_endpoints() {
  print_header "Service Endpoints"
  
  printf "Main Domain: "
  curl -s -o /dev/null -w "%{http_code}\n" "https://$JITSI_DOMAIN/healthz" || printf "FAIL\n"
  
  printf "Keycloak: "
  curl -s -o /dev/null -w "%{http_code}\n" "https://auth.$JITSI_DOMAIN/healthz" || printf "FAIL\n"
}

check_ssl() {
  print_header "SSL Certificate Status"
  
  openssl x509 -in "$JITSI_SSL_CERT_PATH" -noout -dates 2>/dev/null || printf "Unable to check SSL certificate\n"
}

check_logs() {
  print_header "Recent Errors (Last 10)"
  
  tail -n 10 /var/log/casjaysdev/jitsi/setup.log | grep ERROR || printf "No recent errors found\n"
}

# Main
main() {
  printf "JITSI MEET DIAGNOSTIC REPORT\n"
  printf "Generated: %s\n" "`date`"
  printf "Domain: %s\n" "$JITSI_DOMAIN"
  
  check_system_resources
  check_containers
  check_endpoints
  check_ssl
  check_logs
  
  printf "\nDiagnostic report completed.\n"
}

# Execute
main "$@"
EOF
  
  # Replace placeholders
  sed -i "s/SCRIPT_VERSION/$JITSI_SCRIPT_VERSION/g" /usr/local/bin/jitsi-diagnose
  sed -i "s/CREATION_DATE/$JITSI_CREATION_DATE/g" /usr/local/bin/jitsi-diagnose
  chmod 755 /usr/local/bin/jitsi-diagnose
  
  __success "All helper scripts created"
}

# Section 16: Cron Job Configuration
__generate_cron_jobs() {
  __header "Creating Cron Jobs"
  
  # Create cron file
  cat > "$JITSI_CRON_FILE" << EOF
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
##@Version           :  $VERSION
# @@Author           :  Jason Hempstead
# @@Contact          :  jason@casjaysdev.pro
# @@License          :  WTFPL
# @@ReadME           :  jitsi --help
# @@Copyright        :  Copyright: (c) 2025 Jason Hempstead, Casjays Developments
# @@Created          :  `date '+%A, %b %d, %Y %I:%M %p %Z'`
# @@File             :  jitsi
# @@Description      :  Cron jobs for Jitsi Meet Enterprise
# @@Changelog        :  New File
# @@TODO             :  Better documentation
# @@Other            :  
# @@Resource         :  
# @@Terminal App     :  no
# @@sudo/root        :  no
# @@Template         :  cron
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# Room cleanup - every hour
0 * * * * root /usr/local/bin/jitsi-room-cleanup >> $JITSI_CRON_LOG_DIR/room-cleanup.log 2>&1

# Database optimization - daily at 2 AM
0 2 * * * root /usr/local/bin/jitsi-db-optimize >> $JITSI_CRON_LOG_DIR/db-optimize.log 2>&1

# Log cleanup - daily at 3 AM
0 3 * * * root find $JITSI_SCRIPT_LOG_DIR -name "*.log" -mtime +30 -delete >> $JITSI_CRON_LOG_DIR/log-cleanup.log 2>&1

# Daily backup - at 4 AM
0 4 * * * root /usr/local/bin/jitsi-backup-daily daily >> $JITSI_CRON_LOG_DIR/backup.log 2>&1

# Health checks - every 5 minutes
*/5 * * * * root /usr/local/bin/jitsi-health-check >> $JITSI_CRON_LOG_DIR/health-check.log 2>&1

# SSL certificate check - daily at 1 AM
0 1 * * * root openssl x509 -in $JITSI_SSL_CERT_PATH -noout -checkend 604800 || echo "SSL certificate expires within 7 days" | mail -s "SSL Certificate Warning - $JITSI_DOMAIN" root@$JITSI_DOMAIN

# Container update check - weekly on Sunday at 5 AM
0 5 * * 0 root docker images | grep jitsi | awk '{print $1":"$2}' | xargs -I {} docker pull {} >> $JITSI_CRON_LOG_DIR/container-updates.log 2>&1

# Metrics cleanup - weekly on Monday at 6 AM
0 6 * * 1 root find $JITSI_ROOTFS_DIR/data/prometheus -name "*.tmp" -mtime +7 -delete >> $JITSI_CRON_LOG_DIR/metrics-cleanup.log 2>&1

# Cache optimization - daily at 5 AM
0 5 * * * root docker exec jitsi-valkey valkey-cli BGREWRITEAOF >> $JITSI_CRON_LOG_DIR/cache-optimize.log 2>&1

# Mail queue check - every 30 minutes
*/30 * * * * root mailq | grep -q "Mail queue is empty" || echo "Mail queue has pending messages" | mail -s "Mail Queue Alert - $JITSI_DOMAIN" root@$JITSI_DOMAIN

# Disk space check - every 15 minutes
*/15 * * * * root df -h | awk '$5 > 90 {print "Disk usage critical: " $0}' | grep -q . && echo "Disk space critical on $JITSI_DOMAIN" | mail -s "Disk Space Alert" root@$JITSI_DOMAIN

# Recording cleanup - daily at 6 AM
0 6 * * * root find $JITSI_ROOTFS_DIR/data/recordings -name "*.webm" -mtime +30 -delete >> $JITSI_CRON_LOG_DIR/recording-cleanup.log 2>&1

# Weekly backup - Sunday at 2 AM
0 2 * * 0 root /usr/local/bin/jitsi-backup-daily weekly >> $JITSI_CRON_LOG_DIR/backup.log 2>&1

# Password file auto-delete - after 24 hours
0 0 * * * root [ -f "$JITSI_BASE_DIR/.passwords" ] && [ `find "$JITSI_BASE_DIR/.passwords" -mtime +1 | wc -l` -gt 0 ] && rm -f "$JITSI_BASE_DIR/.passwords"
EOF
  
  # Set permissions
  chmod 644 "$JITSI_CRON_FILE"
  chown root:root "$JITSI_CRON_FILE"
  
  __success "Cron jobs configured"
}

# Section 17: Completion Email and Summary
__send_completion_email() {
  JITSI_INSTALL_END_TIME=`date +%s`
  JITSI_INSTALL_DURATION=`expr $JITSI_INSTALL_END_TIME - $JITSI_INSTALL_START_TIME`
  JITSI_INSTALL_MINUTES=`expr $JITSI_INSTALL_DURATION / 60`
  
  JITSI_HOSTNAME=`hostname -f`
  JITSI_PUBLIC_IP=`curl -s https://ipinfo.io/ip 2>/dev/null || printf "Unknown"`
  
  # Create summary file
  JITSI_SUMMARY_FILE="$JITSI_TEMP_DIR/installation_summary.txt"
  
  cat > "$JITSI_SUMMARY_FILE" << EOF
JITSI MEET ENTERPRISE INSTALLATION SUMMARY
==========================================

Installation completed successfully!
Duration: $JITSI_INSTALL_MINUTES minutes

DOMAIN INFORMATION
------------------
Primary Domain: $JITSI_DOMAIN
Hostname: $JITSI_HOSTNAME
Public IP: $JITSI_PUBLIC_IP

ACCESS INFORMATION
------------------
Main Application:
  URL: https://$JITSI_DOMAIN/
  URL: https://meet.$JITSI_DOMAIN/

Authentication (Keycloak):
  Admin Console: https://auth.$JITSI_DOMAIN/admin/
  Username: administrator@$JITSI_DOMAIN
  Password: See .passwords file

Monitoring:
  Grafana: https://grafana.$JITSI_DOMAIN/
  Username: admin
  Password: See .passwords file
  
  Public Stats: https://stats.$JITSI_DOMAIN/
  
  Uptime Kuma: https://uptime.$JITSI_DOMAIN/
  Username: admin
  Password: See .passwords file

Additional Services:
  Whiteboard: https://whiteboard.$JITSI_DOMAIN/
  Etherpad: https://pad.$JITSI_DOMAIN/
  API: https://api.$JITSI_DOMAIN/
  Metrics: https://metrics.$JITSI_DOMAIN/
  Tracing: https://trace.$JITSI_DOMAIN/

SYSTEM INFORMATION
------------------
Operating System: $JITSI_OS_ID $JITSI_OS_VERSION
Docker Version: `docker --version | cut -d' ' -f3 | tr -d ','`
Memory: ${JITSI_SYSTEM_MEMORY_MB}MB
CPU Cores: $JITSI_SYSTEM_CPU_CORES
Disk Space: ${JITSI_SYSTEM_DISK_GB}GB

INSTALLED SERVICES
------------------
$JITSI_CHECKMARK MariaDB Database
$JITSI_CHECKMARK Valkey Cache
$JITSI_CHECKMARK Keycloak Authentication
$JITSI_CHECKMARK Jitsi Web Server
$JITSI_CHECKMARK Prosody XMPP Server
$JITSI_CHECKMARK Jicofo Conference Focus
$JITSI_CHECKMARK JVB Video Bridge
$JITSI_CHECKMARK Etherpad Collaborative Editor
$JITSI_CHECKMARK Excalidraw Whiteboard
$JITSI_CHECKMARK Prometheus Metrics
$JITSI_CHECKMARK Grafana Dashboards
$JITSI_CHECKMARK Jaeger Tracing
$JITSI_CHECKMARK Uptime Kuma Monitoring

CONTAINER CONFIGURATION
-----------------------
Network: $JITSI_DOCKER_NETWORK_NAME
Bridge IP: $JITSI_DOCKER_BRIDGE_IP
Memory Limit: $JITSI_CONTAINER_MEMORY_LIMIT
Shared Memory: $JITSI_SHARED_MEMORY_SIZE

MONITORING & MAINTENANCE
------------------------
Log Directory: $JITSI_SCRIPT_LOG_DIR
Backup Directory: $JITSI_BACKUP_DIR
Cron Jobs: $JITSI_CRON_FILE

Helper Scripts:
  - jitsi-room-cleanup
  - jitsi-db-optimize
  - jitsi-health-check
  - jitsi-backup-daily
  - jitsi-diagnose

NEXT STEPS
----------
1. Save the credentials from: $JITSI_BASE_DIR/.passwords
2. Delete the password file for security
3. Configure Keycloak realms and users
4. Set up monitoring dashboards
5. Test video conferencing functionality

SECURITY NOTICE
---------------
IMPORTANT: The password file contains all service credentials.
It will be automatically deleted in 24 hours for security.
Save these credentials in a secure password manager immediately!

To delete the password file manually:
  rm -f $JITSI_BASE_DIR/.passwords

REQUIRED PORTS
--------------
Ensure the following ports are accessible:
  - 80/tcp (HTTP redirect)
  - 443/tcp (HTTPS)
  - 5222/tcp (XMPP client)
  - 5269/tcp (XMPP server)  
  - 5347/tcp (XMPP component)
  - 10000/udp (JVB media)
  - 4443/tcp (JVB fallback)

For support, check the logs in: $JITSI_SCRIPT_LOG_DIR

Best regards,
Jitsi Meet Enterprise Installer
EOF
  
  # Send email if mail command is available
  if command -v mail >/dev/null 2>&1; then
    mail -s "Jitsi Meet Installation Complete - $JITSI_DOMAIN" "root@$JITSI_DOMAIN" < "$JITSI_SUMMARY_FILE"
  fi
  
  # Display summary on console
  if [ "$JITSI_QUIET_MODE" = "false" ]; then
    cat "$JITSI_SUMMARY_FILE"
  fi
  
  # Clean up
  rm -f "$JITSI_SUMMARY_FILE"
}

# Section 18: Main Installation Function
__main() {
  # Record start time
  JITSI_INSTALL_START_TIME=`date +%s`
  
  # Initialize colors
  __init_colors
  
  # Show banner
  if [ "$JITSI_QUIET_MODE" = "false" ] && [ "$JITSI_RAW_OUTPUT" = "false" ]; then
    __banner
  fi
  
  # Parse command line arguments
  __parse_arguments "$@"
  
  # Check root access
  if [ "$JITSI_INSTALLER_REQUIRE_SUDO" = "yes" ] && [ "`id -u`" != "0" ]; then
    __error "This installer must be run as root or with sudo"
    exit $JITSI_EXIT_PERMISSION
  fi
  
  # Load existing configuration if available
  if [ -f "$JITSI_ENV_FILE" ]; then
    __load_env_file
  fi
  
  # If dry-run mode, just create configuration and exit
  if [ "$JITSI_DRY_RUN" = "true" ]; then
    __info "Running in dry-run mode..."
    __interactive_config
    __create_directory_structure
    __create_env_file
    __info "Configuration created. Review settings in: $JITSI_ENV_FILE"
    exit $JITSI_EXIT_SUCCESS
  fi
  
  # System Verification
  __detect_distribution
  __validate_system_resources
  __optimize_for_host
  __check_prerequisites
  
  # Docker Configuration
  __detect_docker
  if [ "$JITSI_DOCKER_INSTALLED" = "false" ]; then
    __install_docker
  fi
  __detect_docker_bridge
  __create_docker_network
  
  # Configuration
  __interactive_config
  __detect_ssl_certificates
  __validate_ssl_certificates
  
  # Directory Structure
  __create_directory_structure
  __setup_container_permissions
  
  # Configuration Files
  __create_env_file
  __store_passwords
  
  # Nginx Configuration
  __generate_all_vhost_configs
  __test_nginx_config
  
  # Service Deployment
  __header "Deploying Services"
  __deploy_mariadb
  __deploy_valkey
  __deploy_keycloak
  __deploy_prosody
  __deploy_jicofo
  __deploy_jvb
  __deploy_jitsi_server
  __deploy_supporting_services
  
  # Automation Setup
  __generate_helper_scripts
  __generate_cron_jobs
  
  # Installation Complete
  JITSI_INSTALL_END_TIME=`date +%s`
  JITSI_INSTALL_DURATION=`expr $JITSI_INSTALL_END_TIME - $JITSI_INSTALL_START_TIME`
  JITSI_INSTALL_MINUTES=`expr $JITSI_INSTALL_DURATION / 60`
  
  __header "Installation Complete"
  __send_completion_email
  
  __success "Jitsi Meet Enterprise has been successfully installed!"
  __success "Access your instance at: https://$JITSI_DOMAIN/"
  __warning "Remember to save and delete the password file: $JITSI_BASE_DIR/.passwords"
}

# Execute main function only if script is run directly
case "${0##*/}" in
  install.sh|sh|bash|dash)
    __main "$@"
    ;;
esac