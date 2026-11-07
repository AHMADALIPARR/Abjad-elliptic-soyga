/* SPDX-License-Identifier: AGPL-3.0-only
* SPDX-FileCopyrightText: 2026 The algorithm-cores project contributors
*/
#define _POSIX_C_SOURCE 200809L
#include "protocol.h"
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <inttypes.h>
#include <sys/socket.h>
#include <sys/time.h>
#include <sys/un.h>
int main(int argc,char **argv){
    if(argc!=3){fprintf(stderr,"Usage: %s SOCKET ARABIC_TEXT\n",argv[0]);return 2;}
    if(argv[1][0]=='\0'){fprintf(stderr,"empty socket path\n");return 2;}
    size_t n=strlen(argv[2]);
    if(n>RPC_MAX_PAYLOAD){fprintf(stderr,"too long\n");return 2;}
    int fd=socket(AF_UNIX,SOCK_STREAM,0);
    if(fd<0){perror("socket");return 1;}
    struct timeval tv={5,0};
    const char *e=getenv("ABJAD_CLIENT_TIMEOUT_MS");
    if(e&&*e){
        char *end=NULL; errno=0; long ms=strtol(e,&end,10);
        if(errno||end==e||*end||ms<1||ms>120000){fprintf(stderr,"invalid ABJAD_CLIENT_TIMEOUT_MS\n");return 2;}
        tv.tv_sec=ms/1000; tv.tv_usec=(ms%1000)*1000;
    }
    if(setsockopt(fd,SOL_SOCKET,SO_RCVTIMEO,&tv,sizeof tv)<0||
       setsockopt(fd,SOL_SOCKET,SO_SNDTIMEO,&tv,sizeof tv)<0){perror("setsockopt");return 1;}
    struct sockaddr_un a;
    memset(&a,0,sizeof a);
    a.sun_family=AF_UNIX;
    if(strlen(argv[1])>=sizeof a.sun_path){fprintf(stderr,"socket path too long\n");return 2;}
    memcpy(a.sun_path,argv[1],strlen(argv[1])+1);
    if(connect(fd,(struct sockaddr*)&a,sizeof a)<0){perror("connect");return 1;}
    unsigned char h[16];
    put32(h,RPC_MAGIC);put16(h+4,RPC_VERSION);put16(h+6,RPC_ABJAD);
    put32(h+8,1);put32(h+12,(uint32_t)n);
    if(write_all(fd,h,16)<0||(n&&write_all(fd,argv[2],n)<0)){perror("write");return 1;}
    unsigned char reply[24];
    if(read_all(fd,reply,sizeof reply)<0){fprintf(stderr,"short reply\n");return 1;}
    if(load32(reply)!=RPC_MAGIC||load16(reply+4)!=RPC_VERSION||load32(reply+8)!=1||load32(reply+12)!=8){
        fprintf(stderr,"bad reply\n");return 1;
    }
    if(load16(reply+6)!=RPC_OK){fprintf(stderr,"RPC error: %u\n",load16(reply+6));return 1;}
    uint64_t v=0;for(int i=16;i<24;i++) v=(v<<8)|reply[i];
    printf("%" PRIu64 "\n",v);
    close(fd);
    return 0;
}
