//
//  LFUtilities.m
//  LittleFuse
//
//  Created by Kranthi on 28/01/16.
//  Copyright © 2016 XcubeLabs. All rights reserved.
//

#import "LFUtilities.h"

@implementation LFUtilities

+ (NSUInteger)getValueFromHexData:(NSData *)data
{
    NSUInteger intDecValue;
    uint8_t *bytesArr = (uint8_t*)[data bytes];
    NSMutableString *dataString = [[NSMutableString alloc] init];
    for (NSInteger i = [data length]-1; i >= 0; i-- ) {
        [dataString appendFormat:@"%02x", bytesArr[i]];
    }
    
    unsigned int dec;
    NSScanner *scan = [NSScanner scannerWithString:dataString];
    if ([scan scanHexInt:&dec]) {
        intDecValue = dec;
    }
    return intDecValue;
}

+ (NSString *)conversionJFormate:(NSData *)data
{
    NSUInteger intDecValue;
    uint8_t *bytesArr = (uint8_t*)[data bytes];
    NSMutableString *dataString = [[NSMutableString alloc] init];
    for (NSInteger i = [data length]-1; i >= 0; i-- ) {
        [dataString appendFormat:@"%02x", bytesArr[i]];
    }
    
    unsigned int dec;
    NSScanner *scan = [NSScanner scannerWithString:dataString];
    if ([scan scanHexInt:&dec]) {
        intDecValue = dec;
    }
    
    NSString *convertedStr;
    NSInteger maskingVal = 16383;
    NSUInteger val1  = intDecValue & (maskingVal);
    CGFloat val2 = (CGFloat)val1/(maskingVal);

    NSString *convertedVal = [self hexToBinary:dataString];

    convertedVal = [NSString stringWithFormat:@"%@", [convertedVal substringToIndex:2]];
    if ([convertedVal isEqualToString:@"00"]) {
        convertedStr = [NSString stringWithFormat:@"+%0.2f lagging", val2];
    } else if ([convertedVal isEqualToString:@"10"]) {
        convertedStr = [NSString stringWithFormat:@"-%0.2f lagging", val2];
    } else if ([convertedVal isEqualToString:@"01"]) {
        convertedStr = [NSString stringWithFormat:@"+%0.2f leading", val2];
    } else if ([convertedVal isEqualToString:@"11"]) {
        convertedStr = [NSString stringWithFormat:@"-%0.2f leading", val2];
        
    }
    return convertedStr;

}

+ (NSString *)convertToBFormate:(float)val
{
    return [NSString stringWithFormat:@"%0.2f", val/100];
}

+ (NSString *)convertToCFormate:(NSData *)data
{
    uint8_t *bytesArr = (uint8_t*)[data bytes];
    NSMutableString *dataString = [[NSMutableString alloc] init];
    for (NSInteger i = [data length]-1; i >= 0; i-- ) {
        [dataString appendFormat:@"%02x", bytesArr[i]];
    }
    return [dataString uppercaseString];

}

+ (NSString *)convertToDFormate:(float)val
{
    
    return [NSString stringWithFormat:@"%0.2f %%", val/100];
}

+ (NSString *)convertToHFormate:(float)val
{
    
    return [NSString stringWithFormat:@"%0.2f sec", (val/100)];
}

+ (NSString *)convertToLFormate:(double)val
{
    
    return [NSString stringWithFormat:@"%ld sec", (long)val];
}


+ (NSString*)hexToBinary:(NSString*)hexString {
    NSMutableString *retnString = [NSMutableString string];
    for(int i = 0; i < [hexString length]; i++) {
        char c = [[hexString lowercaseString] characterAtIndex:i];
        
        switch(c) {
            case '0': [retnString appendString:@"0000"]; break;
            case '1': [retnString appendString:@"0001"]; break;
            case '2': [retnString appendString:@"0010"]; break;
            case '3': [retnString appendString:@"0011"]; break;
            case '4': [retnString appendString:@"0100"]; break;
            case '5': [retnString appendString:@"0101"]; break;
            case '6': [retnString appendString:@"0110"]; break;
            case '7': [retnString appendString:@"0111"]; break;
            case '8': [retnString appendString:@"1000"]; break;
            case '9': [retnString appendString:@"1001"]; break;
            case 'a': [retnString appendString:@"1010"]; break;
            case 'b': [retnString appendString:@"1011"]; break;
            case 'c': [retnString appendString:@"1100"]; break;
            case 'd': [retnString appendString:@"1101"]; break;
            case 'e': [retnString appendString:@"1110"]; break;
            case 'f': [retnString appendString:@"1111"]; break;
            default : break;
        }
    }
    
    return retnString;
}

@end
