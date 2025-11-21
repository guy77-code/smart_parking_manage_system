# Additional clean files
cmake_minimum_required(VERSION 3.16)

if("${CONFIG}" STREQUAL "" OR "${CONFIG}" STREQUAL "Debug")
  file(REMOVE_RECURSE
  "CMakeFiles/smartparkingui_autogen.dir/AutogenUsed.txt"
  "CMakeFiles/smartparkingui_autogen.dir/ParseCache.txt"
  "smartparkingui_autogen"
  )
endif()
