TARGET=libsnapdbjni.so

LIB_DIR=/mnt/kvs/wisckey_caleb/libs
CC=gcc
INCLUDES=-I"$(JAVA_HOME)/include" -I"$(JAVA_HOME)/include/linux" -I$(LIB_DIR)/../include -I./target/headers
LIBS=-L$(LIB_DIR) -lrt -lsnapdb
SRC=snapdbjni.cc json11.cpp
CXXFLAGS=-std=c++17 -fPIC -O2 -Wall -Wextra

all: $(TARGET)
.PHONY: all install clean

$(TARGET): target
	$(CC) -shared -o $(TARGET) $(SRC) $(INCLUDES) $(LIBS) $(CXXFLAGS)

target:
	(cd .. && mvn -pl site.ycsb:snapdb-binding -am clean package)

install: all
	sudo cp $(TARGET) /usr/lib/jni/$(TARGET)

clean:
	rm -f $(TARGET)
	rm -rf target
	sudo rm -f /usr/lib/jni/$(TARGET)
