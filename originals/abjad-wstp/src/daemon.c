#define _POSIX_C_SOURCE 200809L
#include "protocol.h"
#include "abjad.h"
#include <sys/socket.h>
#include <sys/un.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <inttypes.h>
int wolfram_open(const char*,const char*);
int wolfram_sum(const unsigned char*,size_t,uint64_t*);
void wolfram_close(void);
static volatile sig_atomic_t running=1;
static void stop(int s){(void)s;running=0;}
static int handle(int fd,int use_wstp) {
    unsigned char h[16];
    for(;;) {
        ssize_t first=read(fd,h,1);
        if(first==0)return 0;
        if(first<0||read_all(fd,h+1,15)<0)return -1;
        uint32_t magic=load32(h),reqid=load32(h+8),len=load32(h+12);
        uint16_t ver=load16(h+4),op=load16(h+6);
        if(magic!=RPC_MAGIC||ver!=RPC_VERSION||len>RPC_MAX_PAYLOAD)return -1;
        unsigned char *s=malloc((size_t)len+1);if(!s)return -1;
        if(read_all(fd,s,len)<0){free(s);return -1;}
        s[len]=0;
        uint64_t val=0;
        int rc=op==RPC_ABJAD ? abjad_sum(s,len,&val):-2;
        uint16_t status=rc==0?RPC_OK:RPC_BAD_INPUT;
        if(rc==0 && use_wstp && wolfram_sum(s,len,&val)<0)status=RPC_BACKEND_ERROR;
        free(s);
        unsigned char response[24];
        put32(response,RPC_MAGIC);put16(response+4,RPC_VERSION);
        put16(response+6,status);put32(response+8,reqid);put32(response+12,8);
        for(int i=0;i<8;i++) response[16+i]=(unsigned char)(val>>(56-8*i));
        if(write_all(fd,response,sizeof(response))<0)return -1;
        if(status==RPC_BACKEND_ERROR)return -1;
    }
}
int main(int argc,char **argv) {
    if(argc<3||argc>5|| (strcmp(argv[1],"local") && strcmp(argv[1],"wstp"))) {
        fprintf(stderr,"Usage: %s local SOCKET | %s wstp SOCKET KERNEL_COMMAND PACKAGE_PATH\n",argv[0],argv[0]);return 2;
    }
    int use_wstp=!strcmp(argv[1],"wstp");
    if((use_wstp&&argc!=5)||(!use_wstp&&argc!=3))return 2;
    if(strlen(argv[2])>=sizeof(((struct sockaddr_un*)0)->sun_path))return 2;
    signal(SIGPIPE,SIG_IGN);signal(SIGINT,stop);signal(SIGTERM,stop);
    if(use_wstp && wolfram_open(argv[3],argv[4])<0){fprintf(stderr,"WSTP kernel startup failed\n");wolfram_close();return 1;}
    int fd=socket(AF_UNIX,SOCK_STREAM,0);if(fd<0){perror("socket");return 1;}
    struct sockaddr_un addr={0};addr.sun_family=AF_UNIX;strcpy(addr.sun_path,argv[2]);
    if(bind(fd,(struct sockaddr*)&addr,sizeof(addr))<0){perror("bind");close(fd);return 1;}
    if(listen(fd,16)<0){perror("listen");close(fd);unlink(argv[2]);return 1;}
    fprintf(stderr,"abjad daemon: %s backend, socket %s\n",argv[1],argv[2]);
    while(running){int client=accept(fd,NULL,NULL);if(client<0){if(!running)break;continue;}handle(client,use_wstp);close(client);}
    close(fd);unlink(argv[2]);wolfram_close();return 0;
}
