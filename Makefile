.PHONY: all clean mrproper prepare_bootstrap bootstrap install rescue backup
PARSER_GEN=greg
NQ_PATH=source/rock/frontend/NagaQueen.c
DATE=$(shell date +%Y-%m-%d)
TIME=$(shell date +%H:%M)
#OOC_WARN_FLAGS?=+-w
OOC_OWN_FLAGS=--sourcepath=source -g +-pthread --ignoredefine=ROCK_BUILD_ ${OOC_WARN_FLAGS} --allerrors

# used to be CC?=gcc, but that breaks on mingw where CC is set to 'cc' apparently
CC=gcc
PREFIX?=/usr
MAN_INSTALL_PATH?=/usr/local/man/man1
BIN_INSTALL_PATH?=${PREFIX}/bin

ifdef WINDIR
	OOC_OWN_FLAGS+=+-DROCK_BUILD_DATE=\\\"${DATE}\\\" +-DROCK_BUILD_TIME=\\\"${TIME}\\\"
else
	OOC_OWN_FLAGS+=+-DROCK_BUILD_DATE=\"${DATE}\" +-DROCK_BUILD_TIME=\"${TIME}\" +-rdynamic
endif

OOC?=rock
OOC_CMD=${OOC} ${OOC_OWN_FLAGS} ${OOC_FLAGS}

IS_BOOTSTRAP=$(wildcard build/Makefile)

all: bootstrap

profile:
	OOC='valgrind --tool=callgrind bin/rock -onlycheck' make self

# Regenerate NagaQueen.c from the greg grammar
# you need ../nagaqueen and greg to be in your path
#
# http://github.com/nddrylliog/nagaqueen
# http://github.com/nddrylliog/greg
grammar:
	${PARSER_GEN} ../nagaqueen/grammar/nagaqueen.leg > ${NQ_PATH}
	$(MAKE) snowflake/NagaQueen.o

snowflake/NagaQueen.o: source/rock/frontend/NagaQueen.c
	mkdir -p snowflake
	# ${CC} -std=c99 ${NQ_PATH} -O3 -fomit-frame-pointer -D__OOC_USE_GC__ -w -c -o snowflake/NagaQueen.o
	${CC} -std=c99 ${NQ_PATH} -O0 -g -D__OOC_USE_GC__ -w -c -o snowflake/NagaQueen.o

# Prepares the build/ directory, used for bootstrapping
# The build/ directory contains all the C sources needed to build rock
# and a nice Makefile, too
prepare_bootstrap:
	@echo "Preparing boostrap (in build/ directory)"
	rm -rf build/
	${OOC} -driver=make -sourcepath=source -outpath=c-source rock/rock -o=../bin/c_rock c-source/${NQ_PATH} -v -g +-w
ifeq ($(shell uname -s), FreeBSD)
	sed s/-w.*/-w\ -DROCK_BUILD_DATE=\\\"\\\\\"bootstrapped\\\\\"\\\"\ -DROCK_BUILD_TIME=\\\"\\\\\"\\\\\"\\\"/ build/Makefile > build/Makefile.tmp
	rm build/Makefile
	mv build/Makefile.tmp build/Makefile
else
	sed s/-w.*/-w\ -DROCK_BUILD_DATE=\\\"\\\\\"bootstrapped\\\\\"\\\"\ -DROCK_BUILD_TIME=\\\"\\\\\"\\\\\"\\\"/ -i build/Makefile
endif
	cp ${NQ_PATH} build/c-source/${NQ_PATH}
	@echo "Done!"

boehmgc:
	cd libs && $(MAKE)

# For c-source based rock releases, 'make bootstrap' will compile a version
# of rock from the C sources in build/, then use that version to re-compile itself
bootstrap: boehmgc 
ifneq ($(IS_BOOTSTRAP),)
	@echo "Creating bin/ in case it does not exist."
	mkdir -p bin/
	@echo "Compiling from C source"
	cd build/ && ROCK_DIST=.. $(MAKE)
	@echo "Now re-compiling ourself"
	OOC=bin/c_rock ROCK_DIST=. $(MAKE) self
	@echo "Congrats! you have a boostrapped version of rock in bin/rock now. Have fun!"
else
	@cat BOOTSTRAP
	@exit 1
endif
# Copy the manpage and create a symlink to the binary
install:
	if [ -e ${BIN_INSTALL_PATH}/rock ]; then echo "${BIN_INSTALL_PATH}/rock already exists, overwriting."; rm -f ${BIN_INSTALL_PATH}/rock ${BIN_INSTALL_PATH}/rock.exe; fi
	ln -s $(shell pwd)/bin/rock* ${BIN_INSTALL_PATH}/
	install -d ${MAN_INSTALL_PATH}
	install docs/rock.1 ${MAN_INSTALL_PATH}/

# Regenerate the man page from docs/rock.1.txt You need ascidoc for that
man:
	cd docs/ && a2x -f manpage rock.1.txt

# Compile rock with itself
self: snowflake/NagaQueen.o
	mkdir -p bin/
	${OOC_CMD} rock/rock -o=bin/rock NagaQueen.o

# Save your rock binary under bin/safe_rock
backup:
	cp bin/rock bin/safe_rock

# Attempt to grab a rock bootstrap from Alpaca and recompile
rescue:
	rm -rf build/
	# Note: don't use --no-check-certificate, OSX is retarded
	# Note: someone make a curl fallback already
	wget --no-check-certificate http://www.fileville.net/ooc/bootstrap.tar.bz2 -O - | tar xjvmp 1>/dev/null
	if [ ! -e build ]; then cp -rfv rock-*/build ./; fi	
	$(MAKE) clean bootstrap

# Compile rock with the backup'd version of itself
safe:
	OOC_SDK=../rock-master/sdk OOC=bin/safe_rock $(MAKE) self

# Clean all temporary files that may make a build fail
clean:
	rm -rf *_tmp/ .libs snowflake/
	rm -rf `find build/ -name '*.o'`
