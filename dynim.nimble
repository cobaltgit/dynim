# Package

version       = "1.0.1"
author        = "cobaltgit"
description   = "Lightweight Dynu DDNS update client"
license       = "GPL-3.0-or-later"
srcDir        = "src"
binDir        = "bin"
bin           = @["dynim"]

# Dependencies

requires "nim >= 2.0.8"
requires "chronos"

import std/strformat

const relCFlags = "-Os -flto -ffunction-sections -fdata-sections -fomit-frame-pointer -fno-unwind-tables -fno-asynchronous-unwind-tables"
const relLFlags = "-flto -Wl,--gc-sections,--as-needed,--strip-all"
const crossTargets = @[
    ("amd64", "x86_64-linux-musl", "linux-x86_64"),
    ("arm64", "aarch64-linux-musl", "linux-arm64"),
    ("i386", "x86-linux-musl", "linux-i686"),
    ("arm", "arm-linux-musleabihf", "linux-armhf"),
    ("amd64", "x86_64-windows-gnu", "windows-x86_64"),
    ("i386", "x86-windows-gnu", "windows-i686"),
]

proc zigBuild(cpu, triple, label: string) =
    let isWindows = "windows" in triple
    let outName = if isWindows: &"{binDir}/dynim-{label}.exe" else: &"{binDir}/dynim-{label}"
    let passL = if isWindows: &"'-target {triple} {relLFlags}'"
                else: &"'-target {triple} {relLFlags} -static'"
    let os = if isWindows: "windows" else: "linux"
    selfExec &"""c -d:release --opt:size --os:{os} --cpu:{cpu} \
        --cc:clang --clang.exe:zigcc --clang.linkerexe:zigcc \
        --passC:'-target {triple} {relCFlags}' --passL:{passL} \
        -o:{outName} src/dynim.nim"""

task static, "Build static binary linked to musl libc":
    selfExec &"""c -d:release --opt:size --os:linux \
        --cc:gcc --gcc.exe:musl-gcc --gcc.linkerexe:musl-gcc \
        --passC:'{relCFlags}' --passL:'{relLFlags} -static' \
        -o:{binDir}/dynim src/dynim.nim"""

task cross, "Cross-compile static binaries for ARM and x86 (both 32 and 64-bit)":
    for (cpu, triple, label) in crossTargets:
        echo &"===> Building for {triple}"
        zigBuild(cpu, triple, label)

task docker, "Build minimal Docker image":
    exec "docker build -t dynim ."
