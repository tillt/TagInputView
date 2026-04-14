//
//  TagCodec.m
//
//  Tag Editor Codec.
//
//  Created by Till Toenshoff on 04-14-26.
//  Copyright © 2026 Till Toenshoff. All rights reserved.
//

#import "TagCodec.h"

@implementation TagCodec

+ (NSArray<NSString *> *)tagsFromHashtagString:(NSString *)string {
    NSMutableArray<NSString *> *tags = [NSMutableArray array];
    NSUInteger location = 0;
    while (location < string.length) {
        NSRange hashRange = [string rangeOfString:@"#" options:0 range:NSMakeRange(location, string.length - location)];
        if (hashRange.location == NSNotFound) {
            break;
        }

        NSUInteger contentStart = hashRange.location + 1;
        NSRange nextHashRange = [string rangeOfString:@"#" options:0 range:NSMakeRange(contentStart, string.length - contentStart)];
        NSUInteger contentEnd = nextHashRange.location == NSNotFound ? string.length : nextHashRange.location;
        NSString *rawTag = [string substringWithRange:NSMakeRange(contentStart, contentEnd - contentStart)];
        NSString *tag = [rawTag stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (tag.length > 0) {
            [tags addObject:tag];
        }

        location = contentEnd;
    }

    return tags;
}

+ (NSString *)hashtagStringFromTags:(NSArray<NSString *> *)tags {
    NSMutableArray<NSString *> *serializedTags = [NSMutableArray arrayWithCapacity:tags.count];
    for (NSString *tag in tags) {
        NSString *normalizedTag = [tag stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (normalizedTag.length == 0) {
            continue;
        }
        [serializedTags addObject:[@"#" stringByAppendingString:normalizedTag]];
    }

    return [serializedTags componentsJoinedByString:@" "];
}

@end
