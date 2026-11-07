/* SPDX-License-Identifier: AGPL-3.0-only
* SPDX-FileCopyrightText: 2026 The algorithm-cores project contributors
*/
#define _POSIX_C_SOURCE 200809L
#include "../src/abjad.h"
#include <stdio.h>
#include <stdint.h>
#include <time.h>
int main(void){
    enum { N=200, LEN=4096 };
    unsigned char buf[LEN];
    for(int i=0;i<LEN;i+=2){buf[i]=0xD8; buf[i+1]=0xA7;} /* alif */
    struct timespec a,b;
    printf("reps %d bytes %d\n",N,LEN);
    for(int i=0;i<N;i++){
        clock_gettime(CLOCK_MONOTONIC,&a);
        uint64_t v=0;
        int rc=abjad_sum(buf,LEN,&v);
        clock_gettime(CLOCK_MONOTONIC,&b);
        double ns=(b.tv_sec-a.tv_sec)*1e9+(b.tv_nsec-a.tv_nsec);
        if(rc!=0||v!=(uint64_t)(LEN/2)){fprintf(stderr,"bench mismatch\n"); return 1;}
        printf("%.0f\n",ns);
    }
    return 0;
}
