#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

ACTION="${1:-regress}"
TEST="${TEST:-softmax_random_test}"
SEED="${SEED:-1}"
VERBOSITY="${VERBOSITY:-UVM_MEDIUM}"
WAVES="${WAVES:-0}"
COVERAGE="${COVERAGE:-1}"
NUM_ELEMENTS="${NUM_ELEMENTS:-8}"
BUILD_DIR="build/num_${NUM_ELEMENTS}"
LOG_DIR="logs/num_${NUM_ELEMENTS}"
REPORT_DIR="coverage_report/num_${NUM_ELEMENTS}"

mkdir -p "$BUILD_DIR" "$LOG_DIR" waves "$REPORT_DIR"

prepare_mem() {
    if [[ ! -e cordic_angle.mem ]]; then
        if [[ -f ../rtl/cordic_angle.mem ]]; then
            ln -s ../rtl/cordic_angle.mem cordic_angle.mem
        else
            echo "ERROR: cordic_angle.mem was not found in sim/ or rtl/." >&2
            exit 1
        fi
    fi
}

compile() {
    local compile_options=(
        -full64
        -sverilog
        -ntb_opts uvm-1.2
        -timescale=1ns/1ps
        "+define+SOFTMAX_NUM_ELEMENTS=${NUM_ELEMENTS}"
        -f run.f
        -top tb_top
        "-Mdir=${BUILD_DIR}/csrc"
        -o "${BUILD_DIR}/simv"
    )

    if [[ "$WAVES" == "1" ]]; then
        compile_options+=(
            -debug_access+all
            -kdb
            +define+FSDB
        )
    fi

    if [[ "$COVERAGE" == "1" ]]; then
        compile_options+=(
            -cm line+cond+fsm+tgl+branch
            -cm_dir "${BUILD_DIR}/simv.vdb"
        )
    fi

    rm -rf \
        "${BUILD_DIR}/csrc" \
        "${BUILD_DIR}/simv" \
        "${BUILD_DIR}/simv.daidir" \
        "${BUILD_DIR}/simv.vdb"
    vcs "${compile_options[@]}" -l "${LOG_DIR}/compile.log"
}

run_one() {
    local test_name="$1"
    local seed_value="$2"
    local log_file="${LOG_DIR}/${test_name}_${seed_value}.log"
    local simulation_options=(
        "+UVM_TESTNAME=${test_name}"
        "+UVM_VERBOSITY=${VERBOSITY}"
        "+ntb_random_seed=${seed_value}"
    )

    if [[ "$WAVES" == "1" ]]; then
        simulation_options+=(
            "+FSDB_FILE=waves/${test_name}_${seed_value}.fsdb"
        )
    fi

    if [[ "$COVERAGE" == "1" ]]; then
        simulation_options+=(
            -cm line+cond+fsm+tgl+branch
            -cm_dir "${BUILD_DIR}/simv.vdb"
            -cm_name "${test_name}_${seed_value}"
        )
    fi

    echo "[simulate] test=${test_name} seed=${seed_value}"
    "${BUILD_DIR}/simv" "${simulation_options[@]}" -l "$log_file"

    if ! grep -Eq 'UVM_ERROR[[:space:]]*:[[:space:]]*0' "$log_file" ||
       ! grep -Eq 'UVM_FATAL[[:space:]]*:[[:space:]]*0' "$log_file"; then
        echo "ERROR: ${test_name} seed ${seed_value} failed; see ${log_file}." >&2
        exit 1
    fi
}

report() {
    if [[ "$COVERAGE" != "1" ]]; then
        return
    fi

    if ! command -v urg >/dev/null 2>&1; then
        echo "ERROR: urg command was not found in PATH." >&2
        exit 1
    fi

    if [[ ! -d "${BUILD_DIR}/simv.vdb" ]]; then
        echo "ERROR: ${BUILD_DIR}/simv.vdb does not exist." >&2
        exit 1
    fi

    : > "${LOG_DIR}/urg.log"
    set +e
    urg \
        -dir "${BUILD_DIR}/simv.vdb" \
        -format both \
        -report "$REPORT_DIR" \
        2>&1 | tee -a "${LOG_DIR}/urg.log"
    local urg_status=${PIPESTATUS[0]}
    set -e

    if [[ $urg_status -ne 0 ]]; then
        echo "ERROR: URG failed; see ${LOG_DIR}/urg.log." >&2
        exit "$urg_status"
    fi

    echo "[coverage] ${REPORT_DIR}/dashboard.html"
}

prepare_mem

case "$ACTION" in
    single)
        compile
        run_one "$TEST" "$SEED"
        report
        ;;
    regress)
        compile
        run_one softmax_corner_test 1
        run_one softmax_stream_test 2
        run_one softmax_runtime_reset_test 3
        run_one softmax_random_test 1
        run_one softmax_random_test 11
        run_one softmax_random_test 101
        report
        ;;
    report)
        report
        ;;
    clean)
        rm -rf build logs waves coverage_report cordic_angle.mem
        ;;
    *)
        echo "Usage: ./run.sh {single|regress|report|clean}" >&2
        exit 2
        ;;
esac
