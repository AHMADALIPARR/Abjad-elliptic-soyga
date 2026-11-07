#define _POSIX_C_SOURCE 200809L
#include "protocol.h"
#include <sys/socket.h>
#include <sys/un.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <inttypes.h>
int main(int argc,char **argv){
    if(argc!=3){fprintf(stderr,"Usage: %s SOCKET ARABIC_TEXT\n",argv[0]);return 2;}
    size_t n=strlen(argv[2]);if(n>RPC_MAX_PAYLOAD){fprintf(stderr,"too long\n");return 2;}
    int fd=socket(AF_UNIX,SOCK_STREAM,0);if(fd<0){perror("socket");return 1;}
    struct sockaddr_un a={0};a.sun_family=AF_UNIX;
    if(strlen(argv[1])>=sizeof(a.sun_path))return 2;
    strcpy(a.sun_path,argv[1]);
    if(connect(fd,(struct sockaddr*)&a,sizeof(a))<0){perror("connect");return 1;}
    unsigned char h[16];put32(h,RPC_MAGIC);put16(h+4,RPC_VERSION);put16(h+6,RPC_ABJAD);
    put32(h+8,1);put32(h+12,(uint32_t)n);
    if(write_all(fd,h,16)<0||write_all(fd,argv[2],n)<0){perror("write");return 1;}
    unsigned char reply[24];if(read_all(fd,reply,sizeof(reply))<0){fprintf(stderr,"short reply\n");return 1;}
    if(load32(reply)!=RPC_MAGIC||load16(reply+4)!=RPC_VERSION||load32(reply+8)!=1||load32(reply+12)!=8){fprintf(stderr,"bad reply\n");return 1;}
    if(load16(reply+6)!=RPC_OK){fprintf(stderr,"RPC error: %u\n",load16(reply+6));return 1;}
    uint64_t v=0;for(int i=16;i<24;i++)v=(v<<8)|reply[i];
    printf("%" PRIu64 "\n",v);close(fd);return 0;
}
