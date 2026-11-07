/* SPDX-License-Identifier: AGPL-3.0-only
* SPDX-FileCopyrightText: 2026 The algorithm-cores project contributors
*/
#define _POSIX_C_SOURCE 200809L
#include "protocol.h"
#include "abjad.h"
#include <fcntl.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <sys/un.h>
int wolfram_open(const char*,const char*);
int wolfram_sum(const unsigned char*,size_t,uint64_t*);
void wolfram_close(void);

static volatile sig_atomic_t running=1;
static int timeout_ms=5000;
static int max_requests=1024;
static void stop(int s){(void)s;running=0;}

static long env_long(const char *name,long def,long lo,long hi){
    const char *e=getenv(name);
    if(!e||!*e) return def;
    char *end=NULL;
    errno=0;
    long v=strtol(e,&end,10);
    if(errno||end==e||*end||v<lo||v>hi){
        fprintf(stderr,"invalid %s\n",name);
        exit(2);
    }
    return v;
}

static void load_limits(void){
    timeout_ms=(int)env_long("ABJAD_TIMEOUT_MS",5000,1,120000);
    max_requests=(int)env_long("ABJAD_MAX_REQUESTS",1024,1,1000000);
    const char *mode=getenv("ABJAD_SOCKET_MODE");
    if(mode&&strcmp(mode,"0600")!=0){
        fprintf(stderr,"ABJAD_SOCKET_MODE must be 0600\n");
        exit(2);
    }
}

static int set_timeouts(int fd){
    struct timeval tv;
    tv.tv_sec=timeout_ms/1000;
    tv.tv_usec=(timeout_ms%1000)*1000;
    if(setsockopt(fd,SOL_SOCKET,SO_RCVTIMEO,&tv,sizeof tv)<0) return -1;
    if(setsockopt(fd,SOL_SOCKET,SO_SNDTIMEO,&tv,sizeof tv)<0) return -1;
    return 0;
}

static int handle(int fd,int use_wstp){
    unsigned char h[16];
    int nreq=0;
    for(;;){
        if(nreq>=max_requests) return 0;
        ssize_t first=read(fd,h,1);
        if(first==0) return 0;
        if(first<0){if(errno==EINTR) continue; return -1;}
        if(read_all(fd,h+1,15)<0) return -1;
        uint32_t magic=load32(h),reqid=load32(h+8),len=load32(h+12);
        uint16_t ver=load16(h+4),op=load16(h+6);
        if(magic!=RPC_MAGIC||ver!=RPC_VERSION||len>RPC_MAX_PAYLOAD) return -1;
        unsigned char *s=malloc((size_t)len+1);
        if(!s) return -1;
        if(len&&read_all(fd,s,len)<0){free(s);return -1;}
        s[len]=0;
        uint64_t val=0;
        int rc=op==RPC_ABJAD?abjad_sum(s,len,&val):-2;
        uint16_t status=rc==0?RPC_OK:RPC_BAD_INPUT;
        if(rc==0&&use_wstp&&wolfram_sum(s,len,&val)<0) status=RPC_BACKEND_ERROR;
        free(s);
        unsigned char response[24];
        put32(response,RPC_MAGIC);put16(response+4,RPC_VERSION);
        put16(response+6,status);put32(response+8,reqid);put32(response+12,8);
        for(int i=0;i<8;i++) response[16+i]=(unsigned char)(val>>(56-8*i));
        if(write_all(fd,response,sizeof response)<0) return -1;
        nreq++;
        if(status==RPC_BACKEND_ERROR) return -1;
    }
}

int main(int argc,char **argv){
    load_limits();
    if(argc<3||argc>5||(strcmp(argv[1],"local")&&strcmp(argv[1],"wstp"))){
        fprintf(stderr,"Usage: %s local SOCKET | %s wstp SOCKET KERNEL_COMMAND PACKAGE_PATH\n",argv[0],argv[0]);
        return 2;
    }
    int use_wstp=!strcmp(argv[1],"wstp");
    if((use_wstp&&argc!=5)||(!use_wstp&&argc!=3)) return 2;
    if(argv[2][0]=='\0'||strlen(argv[2])>=sizeof(((struct sockaddr_un*)0)->sun_path)) return 2;
    signal(SIGPIPE,SIG_IGN);signal(SIGINT,stop);signal(SIGTERM,stop);
    if(use_wstp&&wolfram_open(argv[3],argv[4])<0){
        fprintf(stderr,"WSTP kernel startup failed\n");
        wolfram_close();
        return 1;
    }
    umask(0077);
    int fd=socket(AF_UNIX,SOCK_STREAM,0);
    if(fd<0){perror("socket");wolfram_close();return 1;}
    if(fcntl(fd,F_SETFD,FD_CLOEXEC)<0){perror("fcntl");close(fd);wolfram_close();return 1;}
    struct stat st;
    if(lstat(argv[2],&st)==0){
        fprintf(stderr,"socket path already exists\n");
        close(fd);wolfram_close();return 1;
    }
    struct sockaddr_un addr;
    memset(&addr,0,sizeof addr);
    addr.sun_family=AF_UNIX;
    memcpy(addr.sun_path,argv[2],strlen(argv[2])+1);
    if(bind(fd,(struct sockaddr*)&addr,sizeof addr)<0){perror("bind");close(fd);wolfram_close();return 1;}
    if(fchmod(fd,S_IRUSR|S_IWUSR)<0 || chmod(argv[2],S_IRUSR|S_IWUSR)<0){
        perror("chmod");close(fd);unlink(argv[2]);wolfram_close();return 1;
    }
    if(listen(fd,16)<0){perror("listen");close(fd);unlink(argv[2]);wolfram_close();return 1;}
    fprintf(stderr,"abjad daemon: %s backend, socket %s, timeout %dms, max requests %d\n",
            argv[1],argv[2],timeout_ms,max_requests);
    while(running){
        int client=accept(fd,NULL,NULL);
        if(client<0){
            if(!running||errno==EINTR){if(!running) break; continue;}
            perror("accept");
            break;
        }
        if(set_timeouts(client)<0){close(client);continue;}
        handle(client,use_wstp);
        close(client);
    }
    close(fd);
    unlink(argv[2]);
    wolfram_close();
    return 0;
}
