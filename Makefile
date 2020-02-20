CC=gcc
COMMON=  -Iinclude/ -Isrc/ -DOPENCV `pkg-config --cflags opencv4` \
	 -DGPU -I/usr/local/cuda/include/
CFLAGS=  -Wall -Wno-unused-result -Wno-unknown-pragmas -Wfatal-errors \
	 -fPIC -DOPENCV -DGPU -Ofast
LDFLAGS= -lm -pthread `pkg-config --libs opencv4` -lstdc++ \
	 -L/usr/local/cuda/lib64 -lcuda -lcudart -lcublas -lcurand

ALIB=darknet/libdarknet.a

main: main.c
	$(CC) $(COMMON) $(CFLAGS) $^ -o $@ $(LDFLAGS) $(ALIB)
