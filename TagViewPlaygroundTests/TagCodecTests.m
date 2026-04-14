#import <XCTest/XCTest.h>

#import "TagCodec.h"

@interface TagCodecTests : XCTestCase
@end

@implementation TagCodecTests

- (void)testTagsFromHashtagStringParsesMultiWordTags {
    NSArray<NSString *> *tags = [TagCodec tagsFromHashtagString:@"#foo bar is cool #bernd is not cool"];
    XCTAssertEqualObjects(tags, (@[@"foo bar is cool", @"bernd is not cool"]));
}

- (void)testHashtagStringFromTagsSerializesTagList {
    NSString *string = [TagCodec hashtagStringFromTags:@[@"foo bar is cool", @"bernd is not cool"]];
    XCTAssertEqualObjects(string, @"#foo bar is cool #bernd is not cool");
}

- (void)testRoundTripPreservesTagBoundaries {
    NSArray<NSString *> *originalTags = @[@"shrieking leads", @"harsh bass", @"journey"];
    NSString *serialized = [TagCodec hashtagStringFromTags:originalTags];
    NSArray<NSString *> *roundTripped = [TagCodec tagsFromHashtagString:serialized];
    XCTAssertEqualObjects(roundTripped, originalTags);
}

@end
