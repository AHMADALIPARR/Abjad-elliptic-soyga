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
#include <sys/stat.h>
#include <sys/un.h>
#include <unistd.h>
#include <wstp.h>

/* Local-only binary RPC: uint16 op_len, uint32 json_len, op bytes, JSON bytes,
   big endian. Reply: uint32 json_len + UTF-8 JSON bytes. Max request 1 MiB. */
#define MAX_PAYLOAD (1024u * 1024u)
#define MAX_OP 64u

static uint16_t read16(const unsigned char *p) { return (uint16_t)((p[0]<<8)|p[1]); }
static uint32_t read32(const unsigned char *p) {
    return ((uint32_t)p[0]<<24)|((uint32_t)p[1]<<16)|((uint32_t)p[2]<<8)|p[3];
}
static void write32(unsigned char *p,uint32_t x) {
    p[0]=(unsigned char)(x>>24);p[1]=(unsigned char)(x>>16);p[2]=(unsigned char)(x>>8);p[3]=(unsigned char)x;
}
static int exact_read(int fd, void *dst, size_t n) {
    unsigned char *p=dst;
    while(n) { ssize_t k=read(fd,p,n); if(k==0)return 0; if(k<0){if(errno==EINTR)continue;return 0;} p+=k;n-=(size_t)k; }
    return 1;
}
static int exact_write(int fd, const void *src, size_t n) {
    const unsigned char *p=src;
    while(n) { ssize_t k=write(fd,p,n); if(k<=0){if(k<0&&errno==EINTR)continue;return 0;}p+=k;n-=(size_t)k; }
    return 1;
}
static int eval_string(WSLINK link, const char *symbol, const char *op, const char *payload, char **answer) {
    int packet, bytes, chars;
    const unsigned char *out=NULL;
    *answer=NULL;
    if(!WSPutFunction(link,"EvaluatePacket",1))return 0;
    if(!WSPutFunction(link,symbol, op ? 2 : 1))return 0;
    if(!WSPutUTF8String(link,(const unsigned char *)(op ? op : payload), (int)strlen(op ? op : payload)))return 0;
    if(op && !WSPutUTF8String(link,(const unsigned char *)payload,(int)strlen(payload)))return 0;
    if(!WSEndPacket(link) || !WSFlush(link))return 0;
    while((packet=WSNextPacket(link)) != 0) {
        if(packet == RETURNPKT) {
            if(!WSGetUTF8String(link,&out,&bytes,&chars))return 0;
            *answer=malloc((size_t)bytes+1u);
            if(*answer){memcpy(*answer,out,(size_t)bytes);(*answer)[bytes]='\0';}
            WSReleaseUTF8String(link,out,bytes);
            return *answer != NULL && WSNewPacket(link);
        }
        if(!WSNewPacket(link))return 0;
    }
    return 0;
}
static int bootstrap(WSLINK link, const char *path) {
    /* Get[path] normally returns Null. To force a UTF-8 result
       we send ToString[If[SameQ[Get[path],$Failed], "error", "ready"]]. Construct syntax tree,
       never build WL source strings from user RPC inputs. */
    int packet,bytes,chars,ok=0;
    const unsigned char *out=NULL;
    if(!WSPutFunction(link,"EvaluatePacket",1) ||
       !WSPutFunction(link,"ToString",1) ||
       !WSPutFunction(link,"If",3) ||
       !WSPutFunction(link,"SameQ",2) ||
       !WSPutFunction(link,"Get",1) ||
       !WSPutUTF8String(link,(const unsigned char*)path,(int)strlen(path)) ||
       !WSPutSymbol(link,"$Failed") ||
       !WSPutUTF8String(link,(const unsigned char*)"error",5) ||
       !WSPutUTF8String(link,(const unsigned char*)"ready",5) ||
       !WSEndPacket(link) || !WSFlush(link))return 0;
    while((packet=WSNextPacket(link))!=0){
        if(packet==RETURNPKT){
            if(WSGetUTF8String(link,&out,&bytes,&chars)){
                ok=(bytes==5&&memcmp(out,"ready",5)==0);
                WSReleaseUTF8String(link,out,bytes);
            }
            WSNewPacket(link);break;
        }
        if(!WSNewPacket(link))break;
    }
    return ok;
}
static void serve(int fd, WSLINK link) {
    unsigned char hdr[6],outlen[4];
    uint16_t op_len; uint32_t payload_len;
    char *op=NULL,*payload=NULL,*result=NULL;
    while(exact_read(fd,hdr,sizeof hdr)){
        op_len=read16(hdr);payload_len=read32(hdr+2);
        if(!op_len || op_len>MAX_OP || payload_len>MAX_PAYLOAD)break;
        op=calloc((size_t)op_len+1,1);payload=calloc((size_t)payload_len+1,1);
        if(!op||!payload)break;
        if(!exact_read(fd,op,op_len)||!exact_read(fd,payload,payload_len))break;
        if(memchr(op,0,op_len)||memchr(payload,0,payload_len))break;
        if(!eval_string(link,"NeuroRegex`Dispatch",op,payload,&result)){
            fprintf(stderr,"WSTP error: %s\n",WSErrorMessage(link));break;
        }
        size_t n=strlen(result);
        if(n>MAX_PAYLOAD)break;
        write32(outlen,(uint32_t)n);
        if(!exact_write(fd,outlen,4)||!exact_write(fd,result,n))break;
        free(op);op=NULL;free(payload);payload=NULL;free(result);result=NULL;
    }
    free(op);free(payload);free(result);
}
int main(int argc, char **argv){
    WSENV env;WSLINK link;int err=-1,server=-1,client=-1;
    struct sockaddr_un addr; const char *socket_path;
    if(argc!=4){fprintf(stderr,"Usage: %s SOCKET_PATH WL_PACKAGE_PATH WSTP_LINK_OPTIONS\nExample WSTP_LINK_OPTIONS: '-linkmode launch -linkname \"WolframKernel -wstp\"'\n",argv[0]);return 2;}
    socket_path=argv[1];
    if(strlen(socket_path)>=sizeof(addr.sun_path)){fprintf(stderr,"socket path too long\n");return 2;}
    env=WSInitialize((WSEnvironmentParameter)0);
    if(!env){fprintf(stderr,"WSInitialize failed\n");return 1;}
    link=WSOpenString(env,argv[3],&err);
    if(!link||err!=WSEOK){fprintf(stderr,"WSOpenString failed: %d\n",err);WSDeinitialize(env);return 1;}
    if(!WSActivate(link)||!bootstrap(link,argv[2])){fprintf(stderr,"could not load Wolfram package\n");WSClose(link);WSDeinitialize(env);return 1;}
    server=socket(AF_UNIX,SOCK_STREAM,0);
    if(server<0){perror("socket");goto finish;}
    memset(&addr,0,sizeof addr);addr.sun_family=AF_UNIX;strcpy(addr.sun_path,socket_path);
    if(unlink(socket_path)<0&&errno!=ENOENT){perror("unlink");goto finish;}
    if(bind(server,(struct sockaddr*)&addr,sizeof addr)<0||chmod(socket_path,S_IRUSR|S_IWUSR)<0||listen(server,8)<0){perror("bind/listen");goto finish;}
    fprintf(stderr,"RPC listening: %s\n",socket_path);
    while((client=accept(server,NULL,NULL))>=0){serve(client,link);close(client);client=-1;}
finish:
    if(client>=0)close(client);
    if(server>=0)close(server);
    unlink(socket_path);WSClose(link);WSDeinitialize(env);
    return 0;
}
