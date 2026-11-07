/* SPDX-License-Identifier: AGPL-3.0-only
* SPDX-FileCopyrightText: 2026 The algorithm-cores project contributors
*/
#include "abjad.h"
#include <stdint.h>
static int value(uint32_t x) {
    switch(x) {
    case 0x0627: case 0x0622: case 0x0623: case 0x0625: case 0x0671: return 1;
    case 0x0628: return 2;
    case 0x062c: return 3;
    case 0x062f: return 4;
    case 0x0647: case 0x0629: return 5;
    case 0x0648: return 6;
    case 0x0632: return 7;
    case 0x062d: return 8;
    case 0x0637: return 9;
    case 0x064a: case 0x0649: return 10;
    case 0x0643: return 20;
    case 0x0644: return 30;
    case 0x0645: return 40;
    case 0x0646: return 50;
    case 0x0633: return 60;
    case 0x0639: return 70;
    case 0x0641: return 80;
    case 0x0635: return 90;
    case 0x0642: return 100;
    case 0x0631: return 200;
    case 0x0634: return 300;
    case 0x062a: return 400;
    case 0x062b: return 500;
    case 0x062e: return 600;
    case 0x0630: return 700;
    case 0x0636: return 800;
    case 0x0638: return 900;
    case 0x063a: return 1000;
    default: return 0;
    }
}
int abjad_sum(const unsigned char *s, size_t n, uint64_t *out) {
    uint64_t sum=0; int matched=0;
    for(size_t i=0;i<n;) {
        uint32_t c; unsigned k;
        unsigned b=s[i];
        if(b<0x80) { c=b; k=1; }
        else if(b>=0xC2 && b<=0xDF) { c=b&31; k=2; }
        else if(b>=0xE0 && b<=0xEF) { c=b&15; k=3; }
        else if(b>=0xF0 && b<=0xF4) { c=b&7; k=4; }
        else return -1;
        if(i+k>n) return -1;
        for(unsigned j=1;j<k;j++) {
            unsigned q=s[i+j]; if((q&0xC0)!=0x80) return -1;
            c=(c<<6)|(q&63);
        }
        if((k==2 && c<0x80)||(k==3 && c<0x800)||(k==4 && c<0x10000)||
           (c>=0xD800&&c<=0xDFFF)||c>0x10FFFF) return -1;
        int v=value(c); if(v) {sum+=(unsigned)v; matched=1;}
        i+=k;
    }
    if(!matched) return -2;
    *out=sum; return 0;
}
