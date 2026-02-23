var CFLAGS = "-Os -flto -ffunction-sections -fdata-sections -fomit-frame-pointer -fno-unwind-tables -fno-asynchronous-unwind-tables"
var LDFLAGS = "-flto -Wl,--gc-sections -Wl,--strip-all"

switch("threads", "off")

when defined(debug): # build debug binary
  CFLAGS = "-Og"
  LDFLAGS = "-fno-lto"
  switch("debugger", "native")
else: # use release flags
  switch("define", "release")
  switch("opt", "size")

when defined(musl): # build musl static binary
  LDFLAGS = LDFLAGS & " -static" # static
  switch("cc", "gcc")
  switch("gcc.exe", "musl-gcc")
  switch("gcc.linkerexe", "musl-gcc")

when defined(static):
  LDFLAGS = LDFLAGS & " -static"

switch("passC", CFLAGS)
switch("passL", LDFLAGS)
