/* SPDX-License-Identifier: AGPL-3.0-only
* SPDX-FileCopyrightText: 2026 The algorithm-cores project contributors
*/
#define _POSIX_C_SOURCE 200809L
#include <errno.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <unistd.h>
#define MAX_PAYLOAD (1024u*1024u)
static int rd(int fd,void *buf,size_t len){unsigned char *p=buf;while(len){ssize_t n=read(fd,p,len);if(n<=0){if(n<0&&errno==EINTR)continue;return 0;}p+=n;len-=n;}return 1;}
static int wr(int fd,const void *buf,size_t len){const unsigned char *p=buf;while(len){ssize_t n=write(fd,p,len);if(n<=0){if(n<0&&errno==EINTR)continue;return 0;}p+=n;len-=n;}return 1;}
int main(int argc,char **argv){
    int fd;struct sockaddr_un sa;unsigned char hdr[6],lenbuf[4];size_t opn,jsn;uint32_t n;char *out;
    if(argc!=4){fprintf(stderr,"Usage: %s SOCKET_PATH operation JSON_OBJECT\n",argv[0]);return 2;}
    opn=strlen(argv[2]);jsn=strlen(argv[3]);
    if(opn==0||opn>64||jsn>MAX_PAYLOAD||strlen(argv[1])>=sizeof(sa.sun_path))return 2;
    memset(&sa,0,sizeof sa);sa.sun_family=AF_UNIX;strcpy(sa.sun_path,argv[1]);
    fd=socket(AF_UNIX,SOCK_STREAM,0);if(fd<0){perror("socket");return 1;}
    if(connect(fd,(struct sockaddr*)&sa,sizeof sa)<0){perror("connect");close(fd);return 1;}
    hdr[0]=(unsigned char)(opn>>8);hdr[1]=(unsigned char)opn;
    hdr[2]=(unsigned char)(jsn>>24);hdr[3]=(unsigned char)(jsn>>16);hdr[4]=(unsigned char)(jsn>>8);hdr[5]=(unsigned char)jsn;
    if(!wr(fd,hdr,6)||!wr(fd,argv[2],opn)||!wr(fd,argv[3],jsn)||!rd(fd,lenbuf,4)){fprintf(stderr,"RPC failure\n");close(fd);return 1;}
    n=((uint32_t)lenbuf[0]<<24)|((uint32_t)lenbuf[1]<<16)|((uint32_t)lenbuf[2]<<8)|lenbuf[3];
    if(n>MAX_PAYLOAD){fprintf(stderr,"response too large\n");close(fd);return 1;}
    out=malloc((size_t)n+1);if(!out||!rd(fd,out,n)){fprintf(stderr,"response read error\n");free(out);close(fd);return 1;}
    out[n]=0;puts(out);free(out);close(fd);return 0;
}
