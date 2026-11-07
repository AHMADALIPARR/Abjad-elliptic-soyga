#include <stddef.h>
#include <stdint.h>
#ifdef WITH_WSTP
#include "wstp.h"
#include <limits.h>
#include <string.h>
static WSENV env;
static WSLINK link;
static int receive_integer(uint64_t *v) {
    for (;;) {
        int p=WSNextPacket(link);
        if(p==0) return -1;
        if(p==RETURNPKT) {
            int64_t x;
            if(!WSGetInteger64(link,&x)||x<0||!WSNewPacket(link))return -1;
            *v=(uint64_t)x; return 0;
        }
        if(!WSNewPacket(link))return -1;
    }
}
int wolfram_open(const char *kernel, const char *package) {
    int err=0;
    char *argv[]={"-linkmode","launch","-linkname",(char *)kernel};
    env=WSInitialize((WSEnvironmentParameter)0);
    if(!env)return -1;
    link=WSOpenArgcArgv(env,4,argv,&err);
    if(!link || err!=WSEOK || !WSActivate(link))return -1;
    if(!WSPutFunction(link,"EvaluatePacket",1) ||
       !WSPutFunction(link,"Get",1) ||
       !WSPutString(link,package) || !WSEndPacket(link) || !WSFlush(link))return -1;
    /* Get[] normally returns Null; consume packet without assuming its numerical form. */
    for(;;) {
        int p=WSNextPacket(link);
        if(!p)return -1;
        if(!WSNewPacket(link))return -1;
        if(p==RETURNPKT)break;
    }
    /* Confirm that the expected package actually defined the function. */
    if(!WSPutFunction(link,"EvaluatePacket",1) ||
       !WSPutFunction(link,"If",3) ||
       !WSPutFunction(link,"NameQ",1) ||
       !WSPutString(link,"AbjadRPC`AbjadValue") ||
       !WSPutInteger32(link,1) || !WSPutInteger32(link,0) ||
       !WSEndPacket(link) || !WSFlush(link))return -1;
    uint64_t present=0;
    return receive_integer(&present)==0 && present==1 ? 0:-1;
}
int wolfram_sum(const unsigned char *s,size_t n,uint64_t *out) {
    if(!link || n>INT_MAX)return -1;
    if(!WSPutFunction(link,"EvaluatePacket",1) ||
       !WSPutFunction(link,"AbjadRPC`AbjadValue",1) ||
       !WSPutUTF8String(link,s,(int)n) ||
       !WSEndPacket(link) || !WSFlush(link))return -1;
    return receive_integer(out);
}
void wolfram_close(void) {
    if(link){WSClose(link);link=NULL;}
    if(env){WSDeinitialize(env);env=NULL;}
}
#else
int wolfram_open(const char *kernel,const char *package){(void)kernel;(void)package;return -1;}
int wolfram_sum(const unsigned char *s,size_t n,uint64_t *out){(void)s;(void)n;(void)out;return -1;}
void wolfram_close(void){}
#endif
