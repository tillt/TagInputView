//
//  TagViewPlaygroundUITests.m
//  TagViewPlaygroundUITests
//
//  Created by Till Toenshoff on 4/13/26.
//

#import <XCTest/XCTest.h>

@interface TagViewPlaygroundUITests : XCTestCase

@property (nonatomic, strong) XCUIApplication *app;

@end

@implementation TagViewPlaygroundUITests

- (void)setUp {
    [super setUp];
    self.continueAfterFailure = NO;
    self.app = [[XCUIApplication alloc] init];
    self.app.launchArguments = @[@"-TagInputUITestEmptyTags"];
    [self.app launch];
}

- (void)tearDown {
    self.app = nil;
    [super tearDown];
}

- (void)testLongFirstDraftUpdatesEditorValue {
    XCUIElement *editor = self.app.groups[@"tag-input-view"];
    if (![editor waitForExistenceWithTimeout:5.0]) {
        NSLog(@"%@", self.app.debugDescription);
    }
    XCTAssertTrue(editor.exists);

    [editor click];
    [self.app typeText:@"waaaaaaaaaaaaaaaaaaaaaaaaaaaaa"];
    [self.app typeText:@"\r"];

    XCUIElement *serializedValue = self.app.staticTexts[@"serialized-value-label"];
    XCTAssertTrue([serializedValue waitForExistenceWithTimeout:2.0]);
    XCTAssertEqualObjects(serializedValue.value, @"#waaaaaaaaaaaaaaaaaaaaaaaaaaaaa");
}

- (void)testRepeatedTabDuplicateEntryKeepsSingleTag {
    XCUIElement *editor = self.app.groups[@"tag-input-view"];
    XCTAssertTrue([editor waitForExistenceWithTimeout:5.0]);

    [editor click];
    [self.app typeText:@"bad\tbad\tbad\r"];

    XCUIElement *serializedValue = self.app.staticTexts[@"serialized-value-label"];
    XCTAssertTrue([serializedValue waitForExistenceWithTimeout:2.0]);
    XCTAssertEqualObjects(serializedValue.value, @"#bad");
}

- (void)testCommaCommitsTagsFromInput {
    XCUIElement *editor = self.app.groups[@"tag-input-view"];
    XCTAssertTrue([editor waitForExistenceWithTimeout:5.0]);

    [editor click];
    [self.app typeText:@"house,warm pad,"];

    XCUIElement *serializedValue = self.app.staticTexts[@"serialized-value-label"];
    XCTAssertTrue([serializedValue waitForExistenceWithTimeout:2.0]);
    XCTAssertEqualObjects(serializedValue.value, @"#house #warm pad");
}

- (void)testLaunchPerformance {
    [self measureWithMetrics:@[[[XCTApplicationLaunchMetric alloc] init]] block:^{
        [[[XCUIApplication alloc] init] launch];
    }];
}

@end
