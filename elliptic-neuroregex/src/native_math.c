/* SPDX-License-Identifier: AGPL-3.0-only
* SPDX-FileCopyrightText: 2026 The algorithm-cores project contributors
*/
#include "native_math.h"
#include <stddef.h>

static int64_t modp(int64_t a, int64_t p){
    int64_t r=a%p;
    if(r<0) r+=p;
    return r;
}
static int mul(int64_t a, int64_t b, int64_t *o){
    __int128 p=(__int128)a*b;
    if(p>INT64_MAX||p<INT64_MIN) return -1;
    *o=(int64_t)p;
    return 0;
}
static int add(int64_t a, int64_t b, int64_t *o){
    __int128 s=(__int128)a+b;
    if(s>INT64_MAX||s<INT64_MIN) return -1;
    *o=(int64_t)s;
    return 0;
}
static int inv(int64_t p, int64_t a, int64_t *o){
    int64_t t=0, newt=1, r=p, newr=modp(a,p);
    if(newr==0) return -1;
    while(newr){
        int64_t q=r/newr;
        int64_t tmp=t-q*newt; t=newt; newt=tmp;
        tmp=r-q*newr; r=newr; newr=tmp;
    }
    if(r!=1) return -1;
    *o=modp(t,p);
    return 0;
}

int magic_cell(int i, int j, int *x, int *y){
    if(i<0||i>2||j<0||j>2||!x||!y) return -1;
    *x=(i+j)%3; *y=j;
    return 0;
}
int magic_certificate(int *distinct, int *lines_ok){
    int m[3][3][2], seen[3][3]={{0}};
    for(int i=0;i<3;i++) for(int j=0;j<3;j++){
        if(magic_cell(i,j,&m[i][j][0],&m[i][j][1])<0) return -1;
        if(seen[m[i][j][0]][m[i][j][1]]) return -1;
        seen[m[i][j][0]][m[i][j][1]]=1;
    }
    int ok=1;
    for(int line=0;line<8;line++){
        int sx=0, sy=0;
        for(int k=0;k<3;k++){
            int i,j;
            if(line<3){i=line;j=k;}
            else if(line<6){i=k;j=line-3;}
            else if(line==6){i=j=k;}
            else {i=k;j=2-k;}
            sx+=m[i][j][0]; sy+=m[i][j][1];
        }
        if((sx%3)!=0||(sy%3)!=0) ok=0;
    }
    if(distinct) *distinct=1;
    if(lines_ok) *lines_ok=ok;
    return ok?0:-1;
}
int discriminant_mod(int64_t p, int64_t a, int64_t b, int64_t *out){
    if(p<=3||!out) return -1;
    int64_t a2,a3,b2,t1,t2,s;
    if(mul(a,a,&a2)||mul(a2,a,&a3)||mul(b,b,&b2)) return -1;
    if(mul(4,a3,&t1)||mul(27,b2,&t2)||add(t1,t2,&s)) return -1;
    *out=modp(s,p);
    return 0;
}
static int is_square_u(uint64_t n, uint64_t *root){
    uint64_t lo=0, hi=1ULL<<32;
    if(n<hi) hi=n+1;
    while(hi-lo>1){
        uint64_t mid=lo+(hi-lo)/2;
        __int128 sq=(__int128)mid*mid;
        if(sq<=n) lo=mid; else hi=mid;
    }
    if((__int128)lo*lo==n){*root=lo; return 1;}
    return 0;
}
int integral_points(int64_t a, int64_t b, int64_t bound, int64_t *xy, int cap, int *count){
    if(bound<0||bound>10000||!count) return -1;
    int64_t disc;
    /* Nonsingularity is over Z, matching 4a^3+27b^2 != 0, not a mod-p reduction. */
    int64_t a2,a3,b2,t1,t2,s;
    if(mul(a,a,&a2)||mul(a2,a,&a3)||mul(b,b,&b2)||mul(4,a3,&t1)||mul(27,b2,&t2)||add(t1,t2,&s)) return -1;
    if(s==0) return -1;
    (void)disc;
    int n=0;
    for(int64_t x=-bound;x<=bound;x++){
        int64_t x2,x3,ax,v;
        if(mul(x,x,&x2)||mul(x2,x,&x3)||mul(a,x,&ax)||add(x3,ax,&v)||add(v,b,&v)) return -1;
        if(v<0) continue;
        uint64_t r;
        if(!is_square_u((uint64_t)v,&r)) continue;
        if((int64_t)r>bound) continue;
        if(r==0){
            if(n>=cap) return -1;
            if(xy){xy[2*n]=x; xy[2*n+1]=0;}
            n++;
        }else{
            if(n+2>cap) return -1;
            if(xy){
                xy[2*n]=x; xy[2*n+1]=(int64_t)r;
                xy[2*n+2]=x; xy[2*n+3]=-(int64_t)r;
            }
            n+=2;
        }
    }
    *count=n;
    return 0;
}
int curve_add(int64_t p, int64_t a, AffinePoint u, AffinePoint v, AffinePoint *out){
    if(p<=3||!out) return -1;
    if(u.inf){*out=v; return 0;}
    if(v.inf){*out=u; return 0;}
    if(modp(u.x,p)==modp(v.x,p) && modp(u.y+v.y,p)==0){out->inf=1; out->x=0; out->y=0; return 0;}
    int same=modp(u.x,p)==modp(v.x,p) && modp(u.y,p)==modp(v.y,p);
    int64_t num, den, invden, slope, s2, x3, y3;
    if(same){
        int64_t x2;
        if(mul(u.x,u.x,&x2)||mul(3,x2,&num)||add(num,a,&num)) return -1;
        if(mul(2,u.y,&den)) return -1;
    }else{
        num=v.y-u.y; den=v.x-u.x;
    }
    num=modp(num,p); den=modp(den,p);
    if(inv(p,den,&invden)) return -1;
    slope=modp((__int128)num*invden, p);
    if(mul(slope,slope,&s2)) return -1;
    x3=modp(s2-u.x-v.x, p);
    y3=modp((__int128)slope*(u.x-x3)-u.y, p);
    out->inf=0; out->x=x3; out->y=y3;
    return 0;
}
int square_sums_ok(const int64_t m[9]){
    if(!m) return 0;
    int64_t s[8];
    for(int i=0;i<3;i++) s[i]=m[3*i]+m[3*i+1]+m[3*i+2];
    for(int j=0;j<3;j++) s[3+j]=m[j]+m[3+j]+m[6+j];
    s[6]=m[0]+m[4]+m[8];
    s[7]=m[2]+m[4]+m[6];
    for(int i=1;i<8;i++) if(s[i]!=s[0]) return 0;
    return 1;
}
static int pos_square(int64_t n){
    if(n<=0) return 0;
    uint64_t r;
    return is_square_u((uint64_t)n,&r);
}
int square_of_squares_ok(const int64_t m[9]){
    if(!square_sums_ok(m)) return 0;
    for(int i=0;i<9;i++){
        if(!pos_square(m[i])) return 0;
        for(int j=0;j<i;j++) if(m[i]==m[j]) return 0;
    }
    return 1;
}
