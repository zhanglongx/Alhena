# Author: zhanglongx <zhanglongx@gmail.com>

PROGRAM:=alhena
VERBOSE?=@
LINUX_KERNEL=/usr

CC=gcc
SOURCES=analyser/analyser.c analyser/data.c analyser/modules.c \
        analyser/rule.c analyser/variables.c \
        misc/message.c alhena.c
MODULES=modules/dummy.c modules/fi.c modules/fi_low.c\
        modules/peak.c modules/peak_low.c \
        modules/maxday.c modules/minday.c modules/no_upseri.c \
        modules/pl_trade.c

SOURCES+=$(MODULES)

DESTDIR?=./

CFLAGS:=-c -O0 -g -Wall -ffreestanding -I./ -I./analyser -I$(LINUX_KERNEL)/include
LDFLAGS:=-lm
DEPMT:=-MT
DEPMM:=-MM -g0

OBJECTS:=$(patsubst %.c,%.o,$(SOURCES))
EXECUTABLE:=$(PROGRAM)

.PHONY : all clean install uninstall

all: $(EXECUTABLE)

clean:
	$(VERBOSE) rm -f -v $(OBJECTS) $(EXECUTABLE)
		
install: $(EXECUTABLE)
	$(VERBOSE) install -d $(DESTDIR)/bin
	$(VERBOSE) install $(EXECUTABLE) $(DESTDIR)/bin

uninstall:
	$(VERBOSE) rm -f $(DESTDIR)/bin/$(EXECUTABLE)
		
$(EXECUTABLE): .depend $(OBJECTS)
	$(VERBOSE) $(CC) -o $@ $(OBJECTS) $(LDFLAGS)
		
%.o : %.c %.h
	$(VERBOSE) $(CC) $(CFLAGS) $< -o $@

.depend:
	$(VERBOSE) rm -f .depend
	$(VERBOSE) $(foreach SRC, $(SOURCES) $(MODULES), $(CC) $(CFLAGS) $(SRC) $(DEPMT) $(SRC:%.c=%.o) $(DEPMM) 1>> .depend;)

depend: .depend
ifneq ($(wildcard .depend),)
include .depend
endif
