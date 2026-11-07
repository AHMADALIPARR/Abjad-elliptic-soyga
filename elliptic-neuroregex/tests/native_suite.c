/* SPDX-License-Identifier: AGPL-3.0-only
* SPDX-FileCopyrightText: 2026 The algorithm-cores project contributors
*/
#include "../src/native_math.h"
#include <stdio.h>
#include <string.h>
static int failures=0, checks=0;
#define CHECK(c) do{checks++; if(!(c)){fprintf(stderr,"FAIL %d %s\n",__LINE__,#c); failures++;}}while(0)
int main(void){
    int distinct=0, lines=0;
    CHECK(magic_certificate(&distinct,&lines)==0);
    CHECK(distinct==1 && lines==1);
    int x,y; CHECK(magic_cell(0,1,&x,&y)==0 && x==1 && y==1);
    CHECK(magic_cell(2,2,&x,&y)==0 && x==1 && y==2);
    int64_t d=1;
    CHECK(discriminant_mod(97,1,1,&d)==0 && d==31);
    CHECK(discriminant_mod(5,-3,2,&d)==0 && d==0);
    int64_t xy[64]; int count=0;
    CHECK(integral_points(0,1,4,xy,32,&count)==0);
    CHECK(count==5);
    /* x from -4..4: (-1,0),(0,1),(0,-1),(2,3),(2,-3) */
    const int64_t want[5][2]={{-1,0},{0,1},{0,-1},{2,3},{2,-3}};
    for(int i=0;i<5;i++) CHECK(xy[2*i]==want[i][0] && xy[2*i+1]==want[i][1]);
    CHECK(integral_points(-3,2,5,xy,32,&count)<0);
    AffinePoint p={0,0,1}, q, r;
    CHECK(curve_add(5,0,p,p,&q)==0 && q.inf==0 && q.x==0 && q.y==4);
    CHECK(curve_add(5,0,q,p,&r)==0 && r.inf==1);
    AffinePoint a={0,3,6}, b={0,3,91}, o;
    CHECK(curve_add(97,2,a,b,&o)==0 && o.inf==1);
    AffinePoint acc=a;
    for(int k=1;k<5;k++) CHECK(curve_add(97,2,acc,a,&acc)==0);
    CHECK(acc.inf==1);
    int64_t lo[9]={8,1,6,3,5,7,4,9,2};
    CHECK(square_sums_ok(lo)==1);
    CHECK(square_of_squares_ok(lo)==0);
    int64_t bad[9]={8,1,6,3,5,7,4,9,1};
    CHECK(square_sums_ok(bad)==0);
    int64_t zeros[9]={0};
    CHECK(square_of_squares_ok(zeros)==0);
    printf("elliptic native checks=%d failures=%d\n",checks,failures);
    return failures?1:0;
}
