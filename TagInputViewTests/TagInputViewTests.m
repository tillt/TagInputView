//
//  TagInputViewTests.m
//  TagInputViewTests
//
//  Created by Till Toenshoff on 4/15/26.
//

#import <XCTest/XCTest.h>
#import "TagInputView+Private.h"

@interface TagInputViewSuggestionDataSource : NSObject <TagInputViewDataSource>
@property (nonatomic, copy) NSArray<NSString*>* suggestions;
@end

@implementation TagInputViewSuggestionDataSource

- (NSArray<NSString*>*)tagInputView:(TagInputView*)view suggestionsForQuery:(NSString*)query
{
    (void)view;
    (void)query;
    return self.suggestions;
}

@end

@interface TagInputViewTests : XCTestCase

@end

@implementation TagInputViewTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    // XCTest Documentation
    // https://developer.apple.com/documentation/xctest
}

- (void)testSuggestionsOnlyMatchPrefix
{
    TagInputView* view = [[TagInputView alloc] initWithFrame:NSZeroRect];
    TagInputViewSuggestionDataSource* dataSource = [TagInputViewSuggestionDataSource new];
    dataSource.suggestions = @[ @"compulsion", @"hummer", @"Minimal", @"mother" ];
    view.dataSource = dataSource;

    XCTAssertEqualObjects([view orderedSuggestionsForQuery:@"m"], (@[ @"minimal", @"mother" ]));
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
