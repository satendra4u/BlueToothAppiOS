//
//  LFAuthUtils.m
//  Littlefuse
//
//  Created by Ashwin on 10/31/16.
//  Copyright © 2016 XcubeLabs. All rights reserved.
//

#import "LFAuthUtils.h"
#import <CommonCrypto/CommonDigest.h>
#import <NSHash/NSString+NSHash.h>
#import <NSHash/NSData+NSHash.h>

@implementation LFAuthUtils

const char hexArray[] = {'0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f'};
const char RAND_SALT1[] = {
    0xb4, 0x0d, 0x46, 0x4b, 0x3d, 0xb7, 0xee, 0x3e,
    0xb5, 0x6d, 0x4d,0xd9, 0xff, 0x12, 0xdf, 0x31,
    0x39, 0xa8, 0x0d, 0xf1, 0x62, 0xb2, 0xde, 0x05,
    0xbb, 0x9d, 0x80, 0xb7, 0x99, 0x46, 0x8e, 0xae,
    0xdd, 0x20, 0xcf, 0xd1, 0x48, 0xd4, 0x7e, 0x37,
    0x2a, 0x2a, 0x8f, 0x80, 0xb7, 0x4e, 0x42, 0x95,
    0x01, 0xd1, 0x66, 0x9f, 0x0b, 0xce, 0xba, 0xaf,
    0x8f, 0x49, 0x73, 0x23, 0x13, 0xcf, 0x03, 0x41
};

const char RAND_SALT2[] = {
    0x53, 0xd5, 0x38, 0x30,0x1d,0x5d,0x47, 0x60,
    0x11, 0x10, 0xaf, 0x51,0x06,0xa5,0x02, 0xbb,
    0x51, 0x7f, 0xe5, 0xd7,0xb5,0xc3,0x79, 0x47,
    0x25, 0xb7, 0xac, 0x71,0x20,0xf3,0xbb, 0xb4,
    0x57, 0xcb, 0x89, 0x28,0x37,0xdd,0x6a, 0x0a,
    0xad, 0xcf, 0x9d, 0xdd,0x46,0xb2,0x68, 0x98,
    0x3f, 0x2b, 0xd0, 0xd6,0x49,0xe6,0x58, 0xf9,
    0xcd, 0x7f, 0x11, 0xcf,0xbf,0x6f,0x66, 0xcb
};

//const Byte somearr[];

NSData* mSeed;
NSData* mPermKey;
//const char* mMacAddress;
NSData* mNextSeed;
//NSData* mSeed;
//NSData* mPermKey;
NSMutableData* mMacAddress;
//NSData* mNextSeed;


- (void)initWithPassKey:(NSString *)passKey andMacAddress:(NSString *)macAddress andSeed:(const char *)seed {
    NSData *seedData = [self getBytesFromCharArr:seed withLength:32];
    mSeed = seedData;
    mMacAddress = [self dataFromHexString:macAddress];
    NSMutableData* permKeyData = [self computePermKey:passKey mac:mMacAddress];
    mPermKey = permKeyData;
}


- (NSData *)getBytesFromCharArr:(const char*)charArr withLength:(NSInteger)len{
    Byte byteArr[len];
    for (int i = 0; i < len; i++) {
        byteArr[i] = charArr[i];
    }
    return [NSData dataWithBytes:byteArr length:len];
}

- (NSMutableData *)dataFromHexString:(NSString *)hexString {
    const char *chars = [hexString UTF8String];
    int i = 0;
    NSUInteger len = hexString.length;
    
    NSMutableData *data = [NSMutableData dataWithCapacity:len / 2];
    char byteChars[3] = {'\0','\0','\0'};
    unsigned long wholeByte;
    
    while (i < len) {
        byteChars[0] = chars[i++];
        byteChars[1] = chars[i++];
        wholeByte = strtoul(byteChars, NULL, 16);
        [data appendBytes:&wholeByte length:1];
    }
    
    return data;
}

- (void)nextAuthCode {
    mSeed = mNextSeed;
}

- (NSMutableData *)computePermKey:(NSString *)passKey mac:(NSData *)mac {
    
    //    NSMutableData *passKeyBytes = [self dataFromHexString:passKey];
    NSData *randData = [NSData dataWithBytes:RAND_SALT1 length:sizeof(RAND_SALT1)];
    NSData *passkeydata = [passKey dataUsingEncoding:NSUTF8StringEncoding];
    NSLog(@"Pass key data = %@", passkeydata);
    NSMutableData *mutableData = [[NSMutableData alloc]init];
    
    [mutableData appendData:randData];
    [mutableData appendData:mac];
    [mutableData appendData:passkeydata];
    NSData *resultData = [mutableData SHA256];
    NSLog(@"Perm key with single data= %@", resultData);
    return [NSMutableData dataWithData:resultData];
}

- (NSMutableData *)getNewPassKeydata:(NSString *)passKey {
    return [self computePermKey:passKey mac:mMacAddress];
}

- (NSMutableData *)computeAuthCode:(const char *)byteData address:(short)address size:(short)size {
    NSMutableData *fullAuthCode = [self computeFullAuthCodeWithSeed:mSeed permKey:mPermKey data:byteData address:address size:size];
    NSLog(@"Full auth code = %@", fullAuthCode);
    NSMutableData *shortenedAuthCode = [[NSMutableData alloc]init];
    mNextSeed = fullAuthCode;
    for (int i = 0; i<8; i++) {
        NSData *subData = [fullAuthCode subdataWithRange:NSMakeRange(i, 1)];
        [shortenedAuthCode appendData:subData];
    }
    return shortenedAuthCode;
}

- (NSMutableData *)computeFullAuthCodeWithSeed:(NSData *)seed permKey:(NSData *)permKey data:(const char *)data address:(short)address size:(short)size {
    char *baAddress = (char *)malloc(2);
    char *baSize = (char *)malloc(2);
    NSInteger convertedVal = (NSInteger)address;
    baAddress[0] = (convertedVal & 0xff);
    baAddress[1] = ((convertedVal >> 8) & 0xff);
    NSInteger convertedSize = (NSInteger)size;
    baSize[1] = (convertedSize << 8);
    baSize[0] = (convertedSize);
    NSData *randData = [NSData dataWithBytes:RAND_SALT2 length:sizeof(RAND_SALT2)];
    NSData *dataVal = [self getBytesFromCharArr:data withLength:8];
    NSMutableData *mutableData = [[NSMutableData alloc]init];
    
    [mutableData appendData:randData];
    [mutableData appendData:seed];
    [mutableData appendData:permKey];
    NSData *addByt = [NSData dataWithBytes:baAddress length :2];
    [mutableData appendData:addByt];
    NSData *sizeByt = [NSData dataWithBytes:baSize length:2];
    [mutableData appendData:sizeByt];
    [mutableData appendData:dataVal];
    NSData *resultStr = [mutableData SHA256];
    return [NSMutableData dataWithData:resultStr];
}

@end
