# Additional clean files
cmake_minimum_required(VERSION 3.16)

if("${CONFIG}" STREQUAL "" OR "${CONFIG}" STREQUAL "Debug")
  file(REMOVE_RECURSE
  "CMakeFiles/SmartParkingUI_autogen.dir/AutogenUsed.txt"
  "CMakeFiles/SmartParkingUI_autogen.dir/ParseCache.txt"
  "SmartParkingUI_autogen"
  )
endif()
