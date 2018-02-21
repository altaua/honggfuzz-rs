#!/bin/sh -ve
export RUST_BACKTRACE=full

cargo clean
cargo hfuzz clean
cargo update

# build example with instrumentation
cargo hfuzz build --verbose

# clean and prepare hfuzz_workspace
workspace="hfuzz_workspace/example"
rm -rf $workspace
mkdir -p $workspace/input

# fuzz exemple
HFUZZ_RUN_ARGS="-v -N 10000000 --run_time 120 --exit_upon_crash" cargo hfuzz run example

# verify that the fuzzing process found the crash
test "$(cat $workspace/*.fuzz)" = "qwerty"

# build example in debug mode
cargo hfuzz build-debug --verbose

# try to launch the debug executable without the crash file, it should fail with error code 1
set +e
hfuzz_target/*/debug/example
status=$?
set -e
test $status -eq 1

# try to launch the debug executable with the crash file, it should fail with error code 101
set +e
CARGO_HONGGFUZZ_CRASH_FILENAME=$(echo $workspace/*.fuzz) hfuzz_target/*/debug/example
status=$?
set -e
test $status -eq 101

# clean
cargo hfuzz clean
rm -rf hfuzz_workspace

# verify that the hfuzz_target has been cleaned
test ! -e hfuzz_target

# verify that the hfuzz_target has been cleaned
test ! -e hfuzz_target

# verify that no target directory has been created
test ! -e target

# verify that we can build the target without instrumentation
cargo build

# but when we run it, it should fail with a useful error message and status 17
set +e
cargo run
status=$?
set -e
test $status -eq 17

cargo clean

