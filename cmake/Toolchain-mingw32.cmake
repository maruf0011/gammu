# Toolchain configuration for SUSE/Fedora like MinGW32 setup

# the name of the target operating system
SET(CMAKE_SYSTEM_NAME Windows)

# which compilers to use for C and C++
SET(CMAKE_C_COMPILER i686-pc-mingw32-gcc)
SET(CMAKE_CXX_COMPILER i686-pc-mingw32-g++)

# here is the target environment located
SET(CMAKE_FIND_ROOT_PATH  /usr/i686-pc-mingw32/sys-root/mingw/ /home/mcihar/win-cross/crosscompiled)

# adjust the default behaviour of the FIND_XXX() commands:
# search headers and libraries in the target environment, search 
# programs in the host environment
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

# Windows libraries names
set(WIN_LIB_ICONV) # builtin
set(WIN_LIB_INTL libintl-8.dll)
set(WIN_LIB_CURL libcurl-4.dll libidn-11.dll libnspr4.dll nss3.dll libssh2-1.dll ssl3.dll zlib1.dll nssutil3.dll libplc4.dll libplds4.dll libgcrypt-11.dll libgpg-error-0.dll)
set(WIN_LIB_MYSQL libmysql.dll)
set(WIN_LIB_PGSQL libpq.dll)
