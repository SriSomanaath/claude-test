#!/usr/bin/env bash
#
# code-reviewer.sh - Headless Code Review for CI/CD Integration
#
# Usage:
#   ./scripts/code-reviewer.sh [OPTIONS]
#
# Options:
#   -l, --level LEVEL      Check level: quick|standard|full (default: standard)
#   -o, --output FORMAT    Output format: text|json|junit (default: text)
#   -t, --target TARGET    Target: all|backend|frontend (default: all)
#   -f, --file FILE        Output file (default: stdout)
#   --fail-fast            Exit on first failure
#   --no-color             Disable colored output
#   -v, --verbose          Verbose output
#   -h, --help             Show this help message
#
# Environment Variables:
#   CR_LEVEL               Default check level
#   CR_OUTPUT              Default output format
#   CR_TARGET              Default target
#   CR_FAIL_FAST           Enable fail-fast mode (1|0)
#   CR_NO_COLOR            Disable colors (1|0)
#   CR_VERBOSE             Enable verbose mode (1|0)
#   CR_BACKEND_PATH        Path to backend directory
#   CR_FRONTEND_PATH       Path to frontend directory
#
# Exit Codes:
#   0  - All checks passed
#   1  - One or more checks failed
#   2  - Configuration/setup error
#   3  - Dependency missing
#

set -uo pipefail

# ==============================================================================
# Configuration
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Defaults (can be overridden by env vars)
LEVEL="${CR_LEVEL:-standard}"
OUTPUT="${CR_OUTPUT:-text}"
TARGET="${CR_TARGET:-all}"
FAIL_FAST="${CR_FAIL_FAST:-0}"
NO_COLOR="${CR_NO_COLOR:-0}"
VERBOSE="${CR_VERBOSE:-0}"
OUTPUT_FILE=""

BACKEND_PATH="${CR_BACKEND_PATH:-${PROJECT_ROOT}/backend}"
FRONTEND_PATH="${CR_FRONTEND_PATH:-${PROJECT_ROOT}/frontend}"

# Check results storage (portable arrays)
CHECK_NAMES=""
CHECK_STATUSES=""
CHECK_DURATIONS=""
CHECK_OUTPUTS=""
CHECK_COUNT=0
TOTAL_ERRORS=0
TOTAL_WARNINGS=0
START_TIME=""

# Temp directory for storing outputs
TEMP_DIR=""

# ==============================================================================
# Colors and Output Helpers
# ==============================================================================

setup_colors() {
    if [[ "${NO_COLOR}" == "1" ]] || [[ ! -t 1 ]]; then
        RED=""
        GREEN=""
        YELLOW=""
        BLUE=""
        CYAN=""
        BOLD=""
        RESET=""
    else
        RED='\033[0;31m'
        GREEN='\033[0;32m'
        YELLOW='\033[0;33m'
        BLUE='\033[0;34m'
        CYAN='\033[0;36m'
        BOLD='\033[1m'
        RESET='\033[0m'
    fi
}

log_info() {
    if [[ "${OUTPUT}" == "text" ]]; then
        echo -e "${BLUE}[INFO]${RESET} $*" >&2
    fi
}

log_success() {
    if [[ "${OUTPUT}" == "text" ]]; then
        echo -e "${GREEN}[PASS]${RESET} $*" >&2
    fi
}

log_error() {
    if [[ "${OUTPUT}" == "text" ]]; then
        echo -e "${RED}[FAIL]${RESET} $*" >&2
    fi
}

log_warning() {
    if [[ "${OUTPUT}" == "text" ]]; then
        echo -e "${YELLOW}[WARN]${RESET} $*" >&2
    fi
}

log_verbose() {
    if [[ "${VERBOSE}" == "1" ]] && [[ "${OUTPUT}" == "text" ]]; then
        echo -e "${CYAN}[DEBUG]${RESET} $*" >&2
    fi
}

# ==============================================================================
# Utility Functions
# ==============================================================================

show_help() {
    cat << 'EOF'
Headless Code Review for CI/CD Integration

USAGE:
    code-reviewer.sh [OPTIONS]

OPTIONS:
    -l, --level LEVEL      Check level: quick|standard|full (default: standard)
                           quick    - Format checks only (fast)
                           standard - Format + lint + type checks
                           full     - All checks including tests

    -o, --output FORMAT    Output format: text|json|junit (default: text)
                           text  - Human-readable output
                           json  - JSON format for programmatic use
                           junit - JUnit XML for CI systems

    -t, --target TARGET    Target: all|backend|frontend (default: all)

    -f, --file FILE        Write output to FILE (default: stdout)

    --fail-fast            Exit immediately on first failure
    --no-color             Disable colored output
    -v, --verbose          Enable verbose output
    -h, --help             Show this help message

ENVIRONMENT VARIABLES:
    CR_LEVEL               Default check level
    CR_OUTPUT              Default output format
    CR_TARGET              Default target
    CR_FAIL_FAST           Enable fail-fast mode (1|0)
    CR_NO_COLOR            Disable colors (1|0)
    CR_VERBOSE             Enable verbose mode (1|0)
    CR_BACKEND_PATH        Path to backend directory
    CR_FRONTEND_PATH       Path to frontend directory

EXAMPLES:
    # Quick format check in CI
    ./scripts/code-reviewer.sh --level quick --output json

    # Full review with JUnit output for GitHub Actions
    ./scripts/code-reviewer.sh --level full --output junit -f report.xml

    # Backend only, fail fast
    ./scripts/code-reviewer.sh --target backend --fail-fast

EXIT CODES:
    0 - All checks passed
    1 - One or more checks failed
    2 - Configuration/setup error
    3 - Dependency missing
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -l|--level)
                LEVEL="$2"
                shift 2
                ;;
            -o|--output)
                OUTPUT="$2"
                shift 2
                ;;
            -t|--target)
                TARGET="$2"
                shift 2
                ;;
            -f|--file)
                OUTPUT_FILE="$2"
                shift 2
                ;;
            --fail-fast)
                FAIL_FAST="1"
                shift
                ;;
            --no-color)
                NO_COLOR="1"
                shift
                ;;
            -v|--verbose)
                VERBOSE="1"
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                echo "Unknown option: $1" >&2
                show_help
                exit 2
                ;;
        esac
    done

    # Validate options
    case "${LEVEL}" in
        quick|standard|full) ;;
        *) echo "Invalid level: ${LEVEL}" >&2; exit 2 ;;
    esac

    case "${OUTPUT}" in
        text|json|junit) ;;
        *) echo "Invalid output format: ${OUTPUT}" >&2; exit 2 ;;
    esac

    case "${TARGET}" in
        all|backend|frontend) ;;
        *) echo "Invalid target: ${TARGET}" >&2; exit 2 ;;
    esac
}

check_dependencies() {
    local missing=""

    if [[ "${TARGET}" == "all" ]] || [[ "${TARGET}" == "backend" ]]; then
        command -v python3 &>/dev/null || missing="${missing} python3"
    fi

    if [[ "${TARGET}" == "all" ]] || [[ "${TARGET}" == "frontend" ]]; then
        command -v node &>/dev/null || missing="${missing} node"
        command -v npm &>/dev/null || missing="${missing} npm"
    fi

    if [[ -n "${missing}" ]]; then
        echo "Missing dependencies:${missing}" >&2
        exit 3
    fi
}

setup_temp() {
    TEMP_DIR=$(mktemp -d)
    trap cleanup EXIT
}

cleanup() {
    if [[ -n "${TEMP_DIR}" ]] && [[ -d "${TEMP_DIR}" ]]; then
        rm -rf "${TEMP_DIR}"
    fi
}

get_timestamp_ms() {
    if command -v gdate &>/dev/null; then
        gdate +%s%3N
    elif date --version 2>/dev/null | grep -q GNU; then
        date +%s%3N
    else
        # macOS fallback - seconds only
        echo "$(($(date +%s) * 1000))"
    fi
}

get_iso_timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

# ==============================================================================
# Result Storage Functions (portable without associative arrays)
# ==============================================================================

store_result() {
    local name="$1"
    local status="$2"
    local duration="$3"
    local output_file="$4"

    CHECK_COUNT=$((CHECK_COUNT + 1))

    # Store in temp files for later retrieval
    echo "${name}" >> "${TEMP_DIR}/names.txt"
    echo "${status}" >> "${TEMP_DIR}/statuses.txt"
    echo "${duration}" >> "${TEMP_DIR}/durations.txt"
    echo "${output_file}" >> "${TEMP_DIR}/outputs.txt"
}

get_check_count() {
    echo "${CHECK_COUNT}"
}

# ==============================================================================
# Check Runners
# ==============================================================================

run_check() {
    local name="$1"
    local description="$2"
    shift 2
    local cmd=("$@")

    local start_ts
    local end_ts
    local duration
    local output_file
    local exit_code

    log_verbose "Running: ${cmd[*]}"

    start_ts=$(get_timestamp_ms)
    output_file="${TEMP_DIR}/output_${CHECK_COUNT}.txt"

    # Capture output and exit code
    set +e
    "${cmd[@]}" > "${output_file}" 2>&1
    exit_code=$?
    set -e

    end_ts=$(get_timestamp_ms)
    duration=$((end_ts - start_ts))

    # Ensure non-negative duration
    if [[ ${duration} -lt 0 ]]; then
        duration=0
    fi

    if [[ ${exit_code} -eq 0 ]]; then
        store_result "${name}" "passed" "${duration}" ""
        log_success "${description}"
    else
        store_result "${name}" "failed" "${duration}" "${output_file}"
        TOTAL_ERRORS=$((TOTAL_ERRORS + 1))
        log_error "${description}"

        if [[ "${VERBOSE}" == "1" ]] && [[ "${OUTPUT}" == "text" ]]; then
            head -50 "${output_file}" >&2
        fi

        if [[ "${FAIL_FAST}" == "1" ]]; then
            output_results
            exit 1
        fi
    fi
}

# ==============================================================================
# Backend Checks
# ==============================================================================

run_backend_checks() {
    if [[ ! -d "${BACKEND_PATH}" ]]; then
        log_warning "Backend directory not found: ${BACKEND_PATH}"
        return
    fi

    log_info "Running backend checks..."
    cd "${BACKEND_PATH}"

    # Determine tool paths - prefer venv if available
    local venv_bin="${PROJECT_ROOT}/.venv/bin"
    local black_cmd=""
    local isort_cmd=""
    local flake8_cmd=""
    local mypy_cmd=""
    local pytest_cmd=""

    # Check for tools in venv first, then system
    if [[ -x "${venv_bin}/black" ]]; then
        black_cmd="${venv_bin}/black"
    elif command -v black &>/dev/null; then
        black_cmd="black"
    fi

    if [[ -x "${venv_bin}/isort" ]]; then
        isort_cmd="${venv_bin}/isort"
    elif command -v isort &>/dev/null; then
        isort_cmd="isort"
    fi

    if [[ -x "${venv_bin}/flake8" ]]; then
        flake8_cmd="${venv_bin}/flake8"
    elif command -v flake8 &>/dev/null; then
        flake8_cmd="flake8"
    fi

    if [[ -x "${venv_bin}/mypy" ]]; then
        mypy_cmd="${venv_bin}/mypy"
    elif command -v mypy &>/dev/null; then
        mypy_cmd="mypy"
    fi

    if [[ -x "${venv_bin}/pytest" ]]; then
        pytest_cmd="${venv_bin}/pytest"
    elif command -v pytest &>/dev/null; then
        pytest_cmd="pytest"
    fi

    log_verbose "Tool paths: black=${black_cmd:-none}, isort=${isort_cmd:-none}"

    # Quick level: format checks only
    if [[ -n "${black_cmd}" ]]; then
        run_check "backend_black" "Backend: Black formatting" \
            "${black_cmd}" --check --quiet .
    else
        log_warning "black not installed - skipping format check"
    fi

    if [[ -n "${isort_cmd}" ]]; then
        run_check "backend_isort" "Backend: Import sorting (isort)" \
            "${isort_cmd}" --check-only --quiet .
    else
        log_warning "isort not installed - skipping import sort check"
    fi

    # Standard level: add lint and type checks
    if [[ "${LEVEL}" == "standard" ]] || [[ "${LEVEL}" == "full" ]]; then
        if [[ -n "${flake8_cmd}" ]]; then
            run_check "backend_flake8" "Backend: Flake8 linting" \
                "${flake8_cmd}" . --max-line-length=88 --count --statistics
        else
            log_warning "flake8 not installed - skipping lint check"
        fi

        if [[ -n "${mypy_cmd}" ]]; then
            run_check "backend_mypy" "Backend: Type checking (mypy)" \
                "${mypy_cmd}" . --ignore-missing-imports --no-error-summary
        else
            log_warning "mypy not installed - skipping type check"
        fi
    fi

    # Full level: add tests
    if [[ "${LEVEL}" == "full" ]]; then
        if [[ -d "tests" ]] && [[ -n "${pytest_cmd}" ]]; then
            run_check "backend_pytest" "Backend: Unit tests (pytest)" \
                "${pytest_cmd}" tests/ -v --tb=short -q
        elif [[ -d "tests" ]]; then
            log_warning "pytest not installed - skipping tests"
        fi
    fi

    cd "${PROJECT_ROOT}"
}

# ==============================================================================
# Frontend Checks
# ==============================================================================

run_frontend_checks() {
    if [[ ! -d "${FRONTEND_PATH}" ]]; then
        log_warning "Frontend directory not found: ${FRONTEND_PATH}"
        return
    fi

    log_info "Running frontend checks..."
    cd "${FRONTEND_PATH}"

    # Ensure dependencies are installed
    if [[ ! -d "node_modules" ]]; then
        log_warning "node_modules not found - installing dependencies..."
        npm install --silent 2>/dev/null || true
    fi

    # Quick level: lint check only
    if [[ -f "package.json" ]]; then
        if grep -q '"lint"' package.json; then
            run_check "frontend_eslint" "Frontend: ESLint" \
                npm run lint --silent 2>/dev/null || npm run lint
        fi
    fi

    # Standard level: add type check
    if [[ "${LEVEL}" == "standard" ]] || [[ "${LEVEL}" == "full" ]]; then
        if grep -q '"type-check"' package.json 2>/dev/null; then
            run_check "frontend_typecheck" "Frontend: TypeScript type check" \
                npm run type-check --silent 2>/dev/null || npm run type-check
        fi
    fi

    # Full level: add tests and build
    if [[ "${LEVEL}" == "full" ]]; then
        if grep -q '"test"' package.json 2>/dev/null; then
            run_check "frontend_jest" "Frontend: Jest tests" \
                npm test -- --passWithNoTests --watchAll=false 2>/dev/null || npm test -- --passWithNoTests
        fi

        if grep -q '"build"' package.json 2>/dev/null; then
            run_check "frontend_build" "Frontend: Build check" \
                npm run build
        fi
    fi

    cd "${PROJECT_ROOT}"
}

# ==============================================================================
# Output Formatters
# ==============================================================================

output_text() {
    echo ""
    echo "=========================================="
    echo "CODE REVIEW SUMMARY"
    echo "=========================================="
    echo ""
    echo "Level:    ${LEVEL}"
    echo "Target:   ${TARGET}"
    echo "Time:     $(get_iso_timestamp)"
    echo ""

    local passed=0
    local failed=0
    local i=1

    if [[ -f "${TEMP_DIR}/names.txt" ]]; then
        while IFS= read -r name; do
            local status
            local duration
            status=$(sed -n "${i}p" "${TEMP_DIR}/statuses.txt")
            duration=$(sed -n "${i}p" "${TEMP_DIR}/durations.txt")
            local duration_sec
            duration_sec=$(awk "BEGIN {printf \"%.2f\", ${duration}/1000}")

            if [[ "${status}" == "passed" ]]; then
                echo -e "${GREEN}[PASS]${RESET} ${name} (${duration_sec}s)"
                passed=$((passed + 1))
            else
                echo -e "${RED}[FAIL]${RESET} ${name} (${duration_sec}s)"
                failed=$((failed + 1))
            fi
            i=$((i + 1))
        done < "${TEMP_DIR}/names.txt"
    fi

    echo ""
    echo "------------------------------------------"
    echo "Results: ${passed} passed, ${failed} failed"
    echo "------------------------------------------"

    if [[ ${failed} -gt 0 ]]; then
        echo ""
        echo "FAILURES:"
        i=1
        while IFS= read -r name; do
            local status
            local output_file
            status=$(sed -n "${i}p" "${TEMP_DIR}/statuses.txt")
            output_file=$(sed -n "${i}p" "${TEMP_DIR}/outputs.txt")

            if [[ "${status}" == "failed" ]] && [[ -n "${output_file}" ]] && [[ -f "${output_file}" ]]; then
                echo ""
                echo "--- ${name} ---"
                head -30 "${output_file}"
            fi
            i=$((i + 1))
        done < "${TEMP_DIR}/names.txt"
    fi
}

output_json() {
    local checks_json=""
    local first="true"
    local i=1
    local passed=0
    local failed=0

    if [[ -f "${TEMP_DIR}/names.txt" ]]; then
        while IFS= read -r name; do
            local status
            local duration
            local output_file
            local output_content=""

            status=$(sed -n "${i}p" "${TEMP_DIR}/statuses.txt")
            duration=$(sed -n "${i}p" "${TEMP_DIR}/durations.txt")
            output_file=$(sed -n "${i}p" "${TEMP_DIR}/outputs.txt")

            if [[ "${status}" == "passed" ]]; then
                passed=$((passed + 1))
            else
                failed=$((failed + 1))
            fi

            if [[ -n "${output_file}" ]] && [[ -f "${output_file}" ]]; then
                output_content=$(python3 -c "import json,sys; print(json.dumps(sys.stdin.read()))" < "${output_file}" 2>/dev/null || echo '""')
            else
                output_content='""'
            fi

            if [[ "${first}" == "true" ]]; then
                first="false"
            else
                checks_json+=","
            fi

            checks_json+="
    {
      \"name\": \"${name}\",
      \"status\": \"${status}\",
      \"duration_ms\": ${duration},
      \"output\": ${output_content}
    }"
            i=$((i + 1))
        done < "${TEMP_DIR}/names.txt"
    fi

    cat << EOF
{
  "version": "1.0",
  "timestamp": "$(get_iso_timestamp)",
  "level": "${LEVEL}",
  "target": "${TARGET}",
  "summary": {
    "total": ${CHECK_COUNT},
    "passed": ${passed},
    "failed": ${failed}
  },
  "checks": [${checks_json}
  ]
}
EOF
}

output_junit() {
    local total=${CHECK_COUNT}
    local failures=${TOTAL_ERRORS}
    local i=1

    cat << EOF
<?xml version="1.0" encoding="UTF-8"?>
<testsuites name="Code Review" tests="${total}" failures="${failures}" time="0">
  <testsuite name="code-review" tests="${total}" failures="${failures}" timestamp="$(get_iso_timestamp)">
EOF

    if [[ -f "${TEMP_DIR}/names.txt" ]]; then
        while IFS= read -r name; do
            local status
            local duration
            local output_file

            status=$(sed -n "${i}p" "${TEMP_DIR}/statuses.txt")
            duration=$(sed -n "${i}p" "${TEMP_DIR}/durations.txt")
            output_file=$(sed -n "${i}p" "${TEMP_DIR}/outputs.txt")

            local duration_sec
            duration_sec=$(awk "BEGIN {printf \"%.3f\", ${duration}/1000}")

            echo "    <testcase name=\"${name}\" classname=\"code-review\" time=\"${duration_sec}\">"

            if [[ "${status}" == "failed" ]] && [[ -n "${output_file}" ]] && [[ -f "${output_file}" ]]; then
                local output
                output=$(head -50 "${output_file}" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g')
                echo "      <failure message=\"Check failed\"><![CDATA[${output}]]></failure>"
            fi

            echo "    </testcase>"
            i=$((i + 1))
        done < "${TEMP_DIR}/names.txt"
    fi

    cat << EOF
  </testsuite>
</testsuites>
EOF
}

output_results() {
    local output_content

    case "${OUTPUT}" in
        text)
            output_content=$(output_text)
            ;;
        json)
            output_content=$(output_json)
            ;;
        junit)
            output_content=$(output_junit)
            ;;
    esac

    if [[ -n "${OUTPUT_FILE}" ]]; then
        echo "${output_content}" > "${OUTPUT_FILE}"
        log_info "Results written to: ${OUTPUT_FILE}"
    else
        echo "${output_content}"
    fi
}

# ==============================================================================
# Main
# ==============================================================================

main() {
    parse_args "$@"
    setup_colors
    setup_temp

    log_info "Starting code review..."
    log_info "Level: ${LEVEL} | Target: ${TARGET} | Output: ${OUTPUT}"

    check_dependencies

    START_TIME=$(get_timestamp_ms)

    # Initialize result files
    touch "${TEMP_DIR}/names.txt"
    touch "${TEMP_DIR}/statuses.txt"
    touch "${TEMP_DIR}/durations.txt"
    touch "${TEMP_DIR}/outputs.txt"

    # Run checks based on target
    case "${TARGET}" in
        all)
            run_backend_checks
            run_frontend_checks
            ;;
        backend)
            run_backend_checks
            ;;
        frontend)
            run_frontend_checks
            ;;
    esac

    # Output results
    output_results

    # Exit with appropriate code
    if [[ ${TOTAL_ERRORS} -gt 0 ]]; then
        exit 1
    fi

    exit 0
}

main "$@"
