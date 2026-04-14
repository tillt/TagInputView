//
//  TagCodec.h
//
//  Tag Editor Codec.
//
//  Created by Till Toenshoff on 04-14-26.
//  Copyright © 2026 Till Toenshoff. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Serializes and deserializes the hashtag storage format used by the tag editor.
 */
@interface TagCodec : NSObject

/**
 Parses a hashtag storage string into plain tag strings.

 Tags are read from one `#` marker to the next `#` marker, or to the end of the string.

 @param string The serialized hashtag string to parse.
 @return An array of parsed tag strings, excluding empty tags.
 */
+ (NSArray<NSString *> *)tagsFromHashtagString:(NSString *)string;

/**
 Serializes plain tag strings into the hashtag storage format.

 @param tags The plain tag strings to serialize.
 @return A serialized hashtag string such as `#house #warm pad`.
 */
+ (NSString *)hashtagStringFromTags:(NSArray<NSString *> *)tags;

@end

NS_ASSUME_NONNULL_END
