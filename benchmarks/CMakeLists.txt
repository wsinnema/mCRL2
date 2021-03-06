# Print a short message on how to perform the benchmarks.
message(STATUS "To generate the necessary files for benchmarking, build the benchmarks target")

set(BENCHMARK_SCRIPT "" CACHE STRING "Pass the benchmark target (mcrl22lps x y) as the first parameter of this script or binary")
mark_as_advanced(BENCHMARK_SCRIPT)

# Add a benchmark named NAME that uses TOOL on the given INPUT.
function(add_tool_benchmark NAME TOOL INPUT OUTPUT)
  set(TARGET "benchmark_target_${TOOL}_${NAME}")
  set(TEST "benchmark_${TOOL}_${NAME}")

  add_custom_target(${TARGET}
    COMMAND ${BENCHMARK_SCRIPT} $<TARGET_FILE:${TOOL}> ${ARGN} ${INPUT} ${OUTPUT}
  )

  add_test(NAME ${TEST} 
    COMMAND ${CMAKE_COMMAND} "--build" ${CMAKE_BINARY_DIR} "--target" "${TARGET}")
  set_property(TEST ${TEST} PROPERTY LABELS "benchmark_tool")
endfunction()

set(BENCHMARK_WORKSPACE ${CMAKE_BINARY_DIR}/benchmarks)
set(STATESPACE_BENCHMARKS
  "examples/academic/abp/abp.mcrl2"
  "examples/academic/allow/allow.mcrl2"
  "examples/academic/cabp/cabp.mcrl2"
  "examples/academic/dining/dining8.mcrl2"
  "examples/games/clobber/clobber.mcrl2"
  "examples/games/domineering/domineering.mcrl2"
  "examples/games/magic_square/magic_square.mcrl2"
  "examples/games/othello/othello.mcrl2"
  "examples/industrial/1394/1394-fin.mcrl2"
  "examples/industrial/brp/brp.mcrl2"
  "examples/industrial/chatbox/chatbox.mcrl2"
  "examples/industrial/lift/lift3-final.mcrl2"
  "examples/industrial/lift/lift3-init.mcrl2"
  )

# This target is used to generate all intermediate files required for benchmarks. 
add_custom_target(benchmarks)
add_dependencies(benchmarks lps2lts pbes2bool pbessolve generatelts ltsconvert)

foreach(benchmark ${STATESPACE_BENCHMARKS})
  # Obtain just <name>.mcrl2, split off <name> for the benchmark name and output lps <name>.lps
  get_filename_component(MCRL2_FILENAME ${benchmark} NAME)
  string(REPLACE ".mcrl2" "" NAME ${MCRL2_FILENAME})

  set(LPS_FILENAME "${BENCHMARK_WORKSPACE}/${NAME}.lps")
  set(LTS_FILENAME "${BENCHMARK_WORKSPACE}/${NAME}.lts")
  set(NODEADLOCK_PBES_FILENAME "${BENCHMARK_WORKSPACE}/${NAME}.nodeadlock.pbes")

  # Generate the lps for this benchmark.
  add_custom_command(TARGET benchmarks 
    COMMAND mcrl22lps "${CMAKE_SOURCE_DIR}/${benchmark}" "${LPS_FILENAME}"
    )

  # Generate a pbes for the nodeadlock property for this benchmark
  add_custom_command(TARGET benchmarks
    COMMAND lps2pbes -f "${CMAKE_SOURCE_DIR}/examples/modal-formulas/nodeadlock.mcf" "${LPS_FILENAME}" "${NODEADLOCK_PBES_FILENAME}"
    )

  # Benchmark linearisation.
  add_tool_benchmark("${NAME}" mcrl22lps "${CMAKE_SOURCE_DIR}/${benchmark}" "")

  # Benchmark statespace generation.
  add_tool_benchmark("${NAME}" lps2lts "${LPS_FILENAME}" "")
  add_tool_benchmark("${NAME}_jittyc" lps2lts "${LPS_FILENAME}" "" "-rjittyc")

  add_tool_benchmark("${NAME}" generatelts ${LPS_FILENAME} "")
  add_tool_benchmark("${NAME}_jittyc" generatelts "${LPS_FILENAME}" "" "-rjittyc")

  # Benchmark statespace reduction techniques, the first target generates the statespaces.
  add_tool_benchmark("${NAME}_exploration" generatelts "${LPS_FILENAME}" "${LTS_FILENAME}" "-rjittyc")

  add_tool_benchmark("${NAME}_bisim" ltsconvert ${LTS_FILENAME} "" "-ebisim")
  add_tool_benchmark("${NAME}_bisim-gjkw" ltsconvert ${LTS_FILENAME} "" "-ebisim-gjkw")

  add_tool_benchmark("${NAME}_branching-bisim" ltsconvert ${LTS_FILENAME} "" "-ebranching-bisim")
  add_tool_benchmark("${NAME}_branching-bisim-gjkw" ltsconvert ${LTS_FILENAME} "" "-ebranching-bisim-gjkw")

  # The ltsconvert benchmarks benchmarks depend on the generated statespace, the benchmark names are hardcoded and depend
  # on the names generated in add_tool_benchmark.
  set_tests_properties(
    "benchmark_ltsconvert_${NAME}_bisim" 
    "benchmark_ltsconvert_${NAME}_bisim-gjkw" 
    "benchmark_ltsconvert_${NAME}_branching-bisim" 
    "benchmark_ltsconvert_${NAME}_branching-bisim-gjkw" 
    PROPERTIES DEPENDS "benchmark_generatelts_${NAME}_exploration")

  # Benchmark solving PBES
  add_tool_benchmark("${NAME}" pbes2bool ${NODEADLOCK_PBES_FILENAME} "")
  add_tool_benchmark("${NAME}_jittyc" pbes2bool ${NODEADLOCK_PBES_FILENAME} "" "-rjittyc")

  add_tool_benchmark("${NAME}" pbessolve ${NODEADLOCK_PBES_FILENAME} "")
  add_tool_benchmark("${NAME}_jittyc" pbessolve ${NODEADLOCK_PBES_FILENAME} "" "-rjittyc")
endforeach()
