/* SPDX-License-Identifier: AGPL-3.0-only
* SPDX-FileCopyrightText: 2026 The algorithm-cores project contributors
*/
#ifndef RPC_PROTOCOL_H
#define RPC_PROTOCOL_H
#include <errno.h>
#include <stddef.h>
#include <stdint.h>
#include <unistd.h>
#define RPC_MAGIC 0x41424a44u /* ABJD */
#define RPC_VERSION 1u
#define RPC_ABJAD 1u
#define RPC_OK 0u
#define RPC_BAD_INPUT 1u
#define RPC_BACKEND_ERROR 2u
#define RPC_MAX_PAYLOAD 65536u
static inline uint16_t load16(const unsigned char *p){return ((uint16_t)p[0]<<8)|p[1];}
static inline uint32_t load32(const unsigned char *p){return ((uint32_t)p[0]<<24)|((uint32_t)p[1]<<16)|((uint32_t)p[2]<<8)|p[3];}
static inline void put16(unsigned char *p,uint16_t v){p[0]=(unsigned char)(v>>8);p[1]=(unsigned char)v;}
static inline void put32(unsigned char *p,uint32_t v){p[0]=(unsigned char)(v>>24);p[1]=(unsigned char)(v>>16);p[2]=(unsigned char)(v>>8);p[3]=(unsigned char)v;}
static inline int read_all(int fd,void *buf,size_t n){
    size_t i=0;
    while(i<n){
        ssize_t r=read(fd,(char*)buf+i,n-i);
        if(r<0){if(errno==EINTR) continue; return -1;}
        if(r==0) return -1;
        i+=(size_t)r;
    }
    return 0;
}
static inline int write_all(int fd,const void *buf,size_t n){
    size_t i=0;
    while(i<n){
        ssize_t r=write(fd,(const char*)buf+i,n-i);
        if(r<0){if(errno==EINTR) continue; return -1;}
        if(r==0) return -1;
        i+=(size_t)r;
    }
    return 0;
}
#endif
