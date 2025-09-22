import os
import sys

editor = False
debug = False
build = False
if (len(sys.argv) > 1):
    if ("-editor" in sys.argv):
        editor = True
    if ("-debug" in sys.argv):
    	debug = True
    if ("-build" in sys.argv):
        build = True

if (editor):
    os.chdir("editor")

os.chdir("windows")
run = "run.bat"
if (debug):
    run = "run_debug.bat"

if (build):
    run = "build.bat"

if (build and debug):
    run = "build_debug.bat"

if (sys.platform == "darwin"):
    os.chdir("../macos")
    run = "sh run.sh"
    if (debug):
    	run = "sh run_debug.sh"
elif (sys.platform == "linux" or sys.platform == "linux2"):
    os.chdir("../linux")
    run = "sh run.sh"
    if (debug):
    	run = "sh run_debug.sh"
    if (build and debug):
        run = "sh build_debug.sh"


os.system(run)

if (editor): os.chdir("../../")
else: os.chdir("../")
