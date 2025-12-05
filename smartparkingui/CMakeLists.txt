cmake_minimum_required(VERSION 3.21)

project(SmartParkingUI VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

# Find Qt6 components
find_package(Qt6 REQUIRED COMPONENTS Core Network Quick QuickControls2 Charts)

# Set QML import path
set(CMAKE_PREFIX_PATH ${CMAKE_PREFIX_PATH} "${CMAKE_CURRENT_SOURCE_DIR}")

# Source files
set(SOURCES
    src/main.cpp
    src/apiclient.cpp
    src/authmanager.cpp
    src/models/user.cpp
    src/models/vehicle.cpp
    src/models/parkingrecord.cpp
    src/models/paymentrecord.cpp
    src/models/reservationorder.cpp
    src/models/violationrecord.cpp
    src/utils/jsonhelper.cpp
)

# Header files
set(HEADERS
    include/apiclient.h
    include/authmanager.h
    include/models/user.h
    include/models/vehicle.h
    include/models/parkingrecord.h
    include/models/paymentrecord.h
    include/models/reservationorder.h
    include/models/violationrecord.h
    include/utils/jsonhelper.h
)

# QML files
set(QML_FILES
    ui/main.qml
    ui/LoginPage.qml
    ui/UserMainPage.qml
    ui/AdminMainPage.qml
    ui/BookingPage.qml
    ui/ParkingVisualizationPage.qml
    ui/PaymentPage.qml
    ui/ViolationPage.qml
    ui/OrderHistoryPage.qml
    ui/AdminDataPage.qml
)

# Resources
set(RESOURCES
    resources.qrc
)

# Create executable
add_executable(${PROJECT_NAME} ${SOURCES} ${HEADERS} ${QML_FILES} ${RESOURCES})

# Set include directories
target_include_directories(${PROJECT_NAME} PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/include
    ${CMAKE_CURRENT_SOURCE_DIR}/include/models
    ${CMAKE_CURRENT_SOURCE_DIR}/include/utils
)

# Link Qt6 libraries
target_link_libraries(${PROJECT_NAME} PRIVATE
    Qt6::Core
    Qt6::Network
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Charts
)

# Set QML import path
target_compile_definitions(${PROJECT_NAME} PRIVATE
    QT_QML_DEBUG
)

# Install rules
install(TARGETS ${PROJECT_NAME}
    BUNDLE DESTINATION .
    RUNTIME DESTINATION bin
)

