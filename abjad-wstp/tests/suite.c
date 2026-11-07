/* SPDX-License-Identifier: AGPL-3.0-only
* SPDX-FileCopyrightText: 2026 The algorithm-cores project contributors
*/
#define _POSIX_C_SOURCE 200809L
#include "../src/abjad.h"
#include "../src/protocol.h"
#include <errno.h>
#include <fcntl.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/un.h>
#include <sys/wait.h>
#include <time.h>
#include <unistd.h>

static int failures=0;
static int checks=0;
#define CHECK(cond) do{checks++; if(!(cond)){fprintf(stderr,"FAIL %s:%d %s\n",__FILE__,__LINE__,#cond); failures++;}}while(0)

static int value_of(uint32_t c){
    static const uint32_t cp[]={
        0x0627,0x0622,0x0623,0x0625,0x0671,0x0628,0x062c,0x062f,0x0647,0x0629,
        0x0648,0x0632,0x062d,0x0637,0x064a,0x0649,0x0643,0x0644,0x0645,0x0646,
        0x0633,0x0639,0x0641,0x0635,0x0642,0x0631,0x0634,0x062a,0x062b,0x062e,
        0x0630,0x0636,0x0638,0x063a};
    static const int val[]={
        1,1,1,1,1,2,3,4,5,5,6,7,8,9,10,10,20,30,40,50,60,70,80,90,100,200,300,
        400,500,600,700,800,900,1000};
    for(size_t i=0;i<sizeof val/sizeof val[0];i++) if(cp[i]==c) return val[i];
    return 0;
}

/* Independent of abjad_sum: same UTF-8 rules, separate table lookup. */
static int oracle(const unsigned char *s,size_t n,uint64_t *out){
    uint64_t sum=0; int matched=0;
    for(size_t i=0;i<n;){
        uint32_t c; unsigned k; unsigned b=s[i];
        if(b<0x80){c=b;k=1;}
        else if(b>=0xC2&&b<=0xDF){c=b&31;k=2;}
        else if(b>=0xE0&&b<=0xEF){c=b&15;k=3;}
        else if(b>=0xF0&&b<=0xF4){c=b&7;k=4;}
        else return -1;
        if(i+k>n) return -1;
        for(unsigned j=1;j<k;j++){
            unsigned q=s[i+j];
            if((q&0xC0)!=0x80) return -1;
            c=(c<<6)|(q&63);
        }
        if((k==2&&c<0x80)||(k==3&&c<0x800)||(k==4&&c<0x10000)||(c>=0xD800&&c<=0xDFFF)||c>0x10FFFF) return -1;
        int v=value_of(c);
        if(v){sum+=(unsigned)v; matched=1;}
        i+=k;
    }
    if(!matched) return -2;
    *out=sum; return 0;
}

static void expect_sum(const unsigned char *s,size_t n,uint64_t want){
    uint64_t got=0, alt=0;
    CHECK(abjad_sum(s,n,&got)==0);
    CHECK(got==want);
    CHECK(oracle(s,n,&alt)==0);
    CHECK(alt==want);
}
static void expect_err(const unsigned char *s,size_t n,int code){
    uint64_t got=0, alt=0;
    CHECK(abjad_sum(s,n,&got)==code);
    CHECK(oracle(s,n,&alt)==code);
}

static pid_t start_daemon(const char *sock){
    pid_t pid=fork();
    if(pid<0){perror("fork"); exit(1);}
    if(pid==0){
        execl("./abjad-daemon","abjad-daemon","local",sock,(char*)NULL);
        _exit(127);
    }
    for(int i=0;i<100;i++){
        struct stat st;
        if(lstat(sock,&st)==0 && S_ISSOCK(st.st_mode)) return pid;
        struct timespec ts={0,20000000L};
        nanosleep(&ts,NULL);
    }
    fprintf(stderr,"daemon socket did not appear\n");
    kill(pid,SIGTERM);
    return -1;
}
static void stop_daemon(pid_t pid,const char *sock){
    if(pid>0){kill(pid,SIGTERM); waitpid(pid,NULL,0);}
    unlink(sock);
}
static int connect_sock(const char *sock){
    int fd=-1;
    for(int i=0;i<50;i++){
        fd=socket(AF_UNIX,SOCK_STREAM,0);
        if(fd<0) return -1;
        struct sockaddr_un a; memset(&a,0,sizeof a);
        a.sun_family=AF_UNIX;
        memcpy(a.sun_path,sock,strlen(sock)+1);
        if(connect(fd,(struct sockaddr*)&a,sizeof a)==0) return fd;
        close(fd);
        struct timespec ts={0,20000000L};
        nanosleep(&ts,NULL);
    }
    return -1;
}
static int rpc(int fd,uint32_t id,uint16_t op,const unsigned char *payload,uint32_t n,uint16_t *status,uint64_t *value,uint32_t *echo){
    unsigned char h[16];
    put32(h,RPC_MAGIC); put16(h+4,RPC_VERSION); put16(h+6,op); put32(h+8,id); put32(h+12,n);
    if(write_all(fd,h,16)<0) return -1;
    if(n&&write_all(fd,payload,n)<0) return -1;
    unsigned char r[24];
    if(read_all(fd,r,24)<0) return -1;
    if(load32(r)!=RPC_MAGIC||load16(r+4)!=RPC_VERSION||load32(r+12)!=8) return -2;
    *status=load16(r+6); *echo=load32(r+8); *value=0;
    for(int i=0;i<8;i++) *value=(*value<<8)|r[16+i];
    return 0;
}

static void unit_tests(void){
    const unsigned char allah[]={0xD8,0xA7,0xD9,0x84,0xD9,0x84,0xD9,0x87};
    const unsigned char muhammad[]={0xD9,0x85,0xD8,0xAD,0xD9,0x85,0xD8,0xAF};
    const unsigned char ahmad[]={0xD8,0xA3,0xD8,0xAD,0xD9,0x85,0xD8,0xAF};
    const unsigned char ali[]={0xD8,0xB9,0xD9,0x84,0xD9,0x8A};
    const unsigned char all28[]=
        "\xD8\xA7\xD8\xA8\xD8\xAC\xD8\xAF\xD9\x87\xD9\x88\xD8\xB2\xD8\xAD\xD8\xB7\xD9\x8A"
        "\xD9\x83\xD9\x84\xD9\x85\xD9\x86\xD8\xB3\xD8\xB9\xD9\x81\xD8\xB5\xD9\x82\xD8\xB1"
        "\xD8\xB4\xD8\xAA\xD8\xAB\xD8\xAE\xD8\xB0\xD8\xB6\xD8\xB8\xD8\xBA";
    expect_sum(allah,sizeof allah,66);
    expect_sum(muhammad,sizeof muhammad,92);
    expect_sum(ahmad,sizeof ahmad,53);
    expect_sum(ali,sizeof ali,110);
    expect_sum(all28,28*2,5995);
    /* aliases and ignored marks */
    const unsigned char teh[]={0xD8,0xA9}; expect_sum(teh,2,5);
    const unsigned char alef_maksura[]={0xD9,0x89}; expect_sum(alef_maksura,2,10);
    const unsigned char alef_madda[]={0xD8,0xA2}; expect_sum(alef_madda,2,1);
    const unsigned char wasla[]={0xD9,0xB1}; expect_sum(wasla,2,1);
    const unsigned char hamza_allah[]={0xD8,0xA1,0xD8,0xA7,0xD9,0x84,0xD9,0x84,0xD9,0x87};
    expect_sum(hamza_allah,sizeof hamza_allah,66);
    const unsigned char marked[]={0xD8,0xA7,0xD9,0x84,0xD9,0x84,0xD9,0x91,0xD9,0x8E,0xD9,0x87};
    expect_sum(marked,sizeof marked,66); /* shadda + fatha ignored */
    const unsigned char tatweel[]={0xD8,0xA7,0xD9,0x80,0xD9,0x84,0xD9,0x84,0xD9,0x87};
    expect_sum(tatweel,sizeof tatweel,66);
    const unsigned char mixed[]="A \xD8\xA7\xD9\x84\xD9\x84\xD9\x87!";
    expect_sum(mixed,sizeof mixed-1,66);
    const unsigned char yeh_hamza[]={0xD8,0xA6}; expect_err(yeh_hamza,1,-1); /* truncated */
    expect_err(yeh_hamza,2,-2); /* U+0626 is not in the abjad table */
    expect_err((const unsigned char*)"",0,-2);
    expect_err((const unsigned char*)"ABC",3,-2);
    expect_err((const unsigned char*)"...",3,-2);
    const unsigned char only_hamza[]={0xD8,0xA1}; expect_err(only_hamza,2,-2);
    const unsigned char null_letter[]={0x00,0xD8,0xA7}; expect_sum(null_letter,3,1);
    const unsigned char overlong[]={0xC0,0xAF}; expect_err(overlong,2,-1);
    const unsigned char overlong3[]={0xE0,0x80,0x80}; expect_err(overlong3,3,-1);
    const unsigned char surrogate[]={0xED,0xA0,0x80}; expect_err(surrogate,3,-1);
    const unsigned char too_big[]={0xF4,0x90,0x80,0x80}; expect_err(too_big,4,-1);
    const unsigned char bad_cont[]={0xE0,0x20,0x80}; expect_err(bad_cont,3,-1);
    const unsigned char lone[]={0x80}; expect_err(lone,1,-1);
    uint32_t rng=1;
    for(int t=0;t<400;t++){
        unsigned char buf[48];
        int n=(int)(rng%49u); rng=rng*1664525u+1013904223u;
        for(int i=0;i<n;i++){rng=rng*1664525u+1013904223u; buf[i]=(unsigned char)(rng>>24);}
        uint64_t a=0,b=0; int ra=abjad_sum(buf,(size_t)n,&a); int rb=oracle(buf,(size_t)n,&b);
        CHECK(ra==rb);
        CHECK(ra==0||ra==-1||ra==-2);
        if(ra==0) CHECK(a==b && a>0);
    }
}

static void protocol_tests(void){
    char sock[]="/tmp/abjad-suite-XXXXXX";
    int tfd=mkstemp(sock); if(tfd<0){perror("mkstemp"); failures++; return;}
    close(tfd); unlink(sock);
    pid_t pid=start_daemon(sock);
    CHECK(pid>0);
    struct stat st;
    CHECK(lstat(sock,&st)==0);
    CHECK(S_ISSOCK(st.st_mode));
    CHECK((st.st_mode&0777)==0600);
    int fd=connect_sock(sock);
    CHECK(fd>=0);
    const unsigned char allah[]={0xD8,0xA7,0xD9,0x84,0xD9,0x84,0xD9,0x87};
    const unsigned char muhammad[]={0xD9,0x85,0xD8,0xAD,0xD9,0x85,0xD8,0xAF};
    uint16_t status=9; uint64_t value=0; uint32_t echo=0;
    CHECK(rpc(fd,42,RPC_ABJAD,allah,sizeof allah,&status,&value,&echo)==0);
    CHECK(status==RPC_OK && value==66 && echo==42);
    CHECK(rpc(fd,7,RPC_ABJAD,muhammad,sizeof muhammad,&status,&value,&echo)==0);
    CHECK(status==RPC_OK && value==92 && echo==7);
    CHECK(rpc(fd,9,RPC_ABJAD,(const unsigned char*)"ABC",3,&status,&value,&echo)==0);
    CHECK(status==RPC_BAD_INPUT);
    CHECK(rpc(fd,3,99,allah,sizeof allah,&status,&value,&echo)==0);
    CHECK(status==RPC_BAD_INPUT);
    /* pipeline a second connection */
    int fd2=connect_sock(sock);
    CHECK(fd2>=0);
    unsigned char h[16];
    put32(h,RPC_MAGIC); put16(h+4,RPC_VERSION); put16(h+6,RPC_ABJAD); put32(h+8,11); put32(h+12,sizeof allah);
    unsigned char h2[16];
    put32(h2,RPC_MAGIC); put16(h2+4,RPC_VERSION); put16(h2+6,RPC_ABJAD); put32(h2+8,12); put32(h2+12,sizeof muhammad);
    CHECK(write_all(fd2,h,16)==0 && write_all(fd2,allah,sizeof allah)==0);
    CHECK(write_all(fd2,h2,16)==0 && write_all(fd2,muhammad,sizeof muhammad)==0);
    unsigned char r1[24], r2[24];
    CHECK(read_all(fd2,r1,24)==0 && read_all(fd2,r2,24)==0);
    CHECK(load32(r1+8)==11 && r1[16]==0 && r1[23]==66);
    CHECK(load32(r2+8)==12 && r2[23]==92);
    close(fd2);
    /* bad magic drops the connection; daemon stays up */
    int fd3=connect_sock(sock);
    CHECK(fd3>=0);
    unsigned char bad[16]={0};
    CHECK(write_all(fd3,bad,16)==0);
    unsigned char sink[8];
    CHECK(read(fd3,sink,sizeof sink)<=0);
    close(fd3);
    int fd4=connect_sock(sock);
    CHECK(fd4>=0);
    put32(h,0x41424a44); put16(h+4,2); put16(h+6,RPC_ABJAD); put32(h+8,1); put32(h+12,0);
    CHECK(write_all(fd4,h,16)==0);
    CHECK(read(fd4,sink,sizeof sink)<=0);
    close(fd4);
    int fd5=connect_sock(sock);
    CHECK(fd5>=0);
    put32(h,RPC_MAGIC); put16(h+4,RPC_VERSION); put16(h+6,RPC_ABJAD); put32(h+8,1); put32(h+12,0xFFFFFFFFu);
    CHECK(write_all(fd5,h,16)==0);
    CHECK(read(fd5,sink,sizeof sink)<=0);
    close(fd5);
    close(fd);
    stop_daemon(pid,sock);

    /* request cap */
    char sock2[]="/tmp/abjad-cap-XXXXXX";
    tfd=mkstemp(sock2); CHECK(tfd>=0); close(tfd); unlink(sock2);
    setenv("ABJAD_MAX_REQUESTS","2",1);
    pid=start_daemon(sock2);
    unsetenv("ABJAD_MAX_REQUESTS");
    CHECK(pid>0);
    fd=connect_sock(sock2);
    CHECK(fd>=0);
    CHECK(rpc(fd,1,RPC_ABJAD,allah,sizeof allah,&status,&value,&echo)==0 && value==66);
    CHECK(rpc(fd,2,RPC_ABJAD,allah,sizeof allah,&status,&value,&echo)==0 && value==66);
    CHECK(rpc(fd,3,RPC_ABJAD,allah,sizeof allah,&status,&value,&echo)<0);
    close(fd);
    stop_daemon(pid,sock2);

    /* stalled client times out and the next client still works */
    char sock3[]="/tmp/abjad-time-XXXXXX";
    tfd=mkstemp(sock3); CHECK(tfd>=0); close(tfd); unlink(sock3);
    setenv("ABJAD_TIMEOUT_MS","300",1);
    pid=start_daemon(sock3);
    unsetenv("ABJAD_TIMEOUT_MS");
    CHECK(pid>0);
    int stall=connect_sock(sock3);
    CHECK(stall>=0);
    struct timespec pause={0,800000000L};
    nanosleep(&pause,NULL);
    fd=connect_sock(sock3);
    CHECK(fd>=0);
    CHECK(rpc(fd,1,RPC_ABJAD,allah,sizeof allah,&status,&value,&echo)==0);
    CHECK(value==66);
    close(fd); close(stall);
    stop_daemon(pid,sock3);

    /* wstp mode without the SDK must fail and must not leave a socket */
    char sock4[]="/tmp/abjad-wstp-XXXXXX";
    tfd=mkstemp(sock4); CHECK(tfd>=0); close(tfd); unlink(sock4);
    pid=fork();
    CHECK(pid>=0);
    if(pid==0){
        execl("./abjad-daemon","abjad-daemon","wstp",sock4,"false","wolfram/AbjadRPC.wl",(char*)NULL);
        _exit(127);
    }
    int wst=0; waitpid(pid,&wst,0);
    CHECK(WIFEXITED(wst)&&WEXITSTATUS(wst)!=0);
    CHECK(lstat(sock4,&st)!=0);
}

int main(void){
    signal(SIGPIPE,SIG_IGN);
    unit_tests();
    protocol_tests();
    printf("abjad suite checks=%d failures=%d\n",checks,failures);
    return failures?1:0;
}
