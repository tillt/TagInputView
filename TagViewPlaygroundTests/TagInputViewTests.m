#import <XCTest/XCTest.h>

#import "TagInputView.h"
#import "TagInputView+Private.h"

@interface TagInputViewSuggestionSource : NSObject <TagInputViewDataSource>
@property (nonatomic, copy) NSString *lastQuery;
@property (nonatomic, copy) NSArray<NSString *> *suggestions;
@end

@implementation TagInputViewSuggestionSource

- (NSArray<NSString *> *)tagInputView:(TagInputView *)view suggestionsForQuery:(NSString *)query {
    self.lastQuery = query;
    return self.suggestions ?: @[];
}

@end

@interface TagInputViewStyleDelegate : NSObject <TagInputViewDelegate>
@end

@implementation TagInputViewStyleDelegate

- (NSTokenStyle)tagInputView:(TagInputView *)view tokenStyleForTag:(NSString *)tag {
    return [tag isEqualToString:@"featured"] ? NSTokenStyleSquared : NSTokenStyleNone;
}

@end

@interface TagInputViewActionTarget : NSObject
@property (nonatomic) NSUInteger invocationCount;
- (void)tagInputChanged:(id)sender;
@end

@implementation TagInputViewActionTarget

- (void)tagInputChanged:(id)sender {
    self.invocationCount += 1;
}

@end

@interface TagInputViewTests : XCTestCase
@property (nonatomic, strong) TagInputView *tagInputView;
@end

@implementation TagInputViewTests

- (void)setUp {
    [super setUp];
    self.tagInputView = [[TagInputView alloc] initWithFrame:NSMakeRect(0, 0, 320, 32)];
}

- (void)testSettingTagsNormalizesDeduplicatesAndSorts {
    self.tagInputView.tags = @[@" Journey  ", @"house", @"journey", @"Warm Pad "];
    XCTAssertEqualObjects(self.tagInputView.tags, (@[@"house", @"journey", @"warm pad"]));
}

- (void)testReloadDataMirrorsTagsIntoTokenFieldObjectValue {
    self.tagInputView.tags = @[@"journey", @"warm pad"];
    [self.tagInputView reloadData];
    XCTAssertEqualObjects(self.tagInputView.tokenField.objectValue, (@[@"journey", @"warm pad"]));
}

- (void)testCommitDraftTextAddsNormalizedTag {
    self.tagInputView.draftText = @"  Warm Pad ";
    [self.tagInputView commitDraftText];
    XCTAssertEqualObjects(self.tagInputView.tags, (@[@"warm pad"]));
    XCTAssertEqualObjects(self.tagInputView.textValue, @"");
}

- (void)testCommitDraftTextInsertsAtCurrentInsertionIndex {
    self.tagInputView.sortsTagsAutomatically = NO;
    self.tagInputView.tags = @[@"journey", @"warm pad"];
    self.tagInputView.inputInsertionIndex = 1;
    self.tagInputView.draftText = @"house";
    [self.tagInputView commitDraftText];

    XCTAssertEqualObjects(self.tagInputView.tags, (@[@"journey", @"house", @"warm pad"]));
}

- (void)testEndEditingAndCommitCommitsPendingDraft {
    self.tagInputView.draftText = @"journey";
    [self.tagInputView endEditingAndCommit];
    XCTAssertEqualObjects(self.tagInputView.tags, (@[@"journey"]));
}

- (void)testCommaSeparatedInputCommitsEachTag {
    [self.tagInputView ingestTextInput:@"house, warm pad, journey" commitTrailingToken:YES];
    XCTAssertEqualObjects(self.tagInputView.tags, (@[@"house", @"journey", @"warm pad"]));
}

- (void)testCommaSeparatedInputInsertsCommittedTagsAtCurrentInsertionIndex {
    self.tagInputView.sortsTagsAutomatically = NO;
    self.tagInputView.tags = @[@"journey", @"warm pad"];
    self.tagInputView.inputInsertionIndex = 1;
    [self.tagInputView ingestTextInput:@"house, dreamy" commitTrailingToken:YES];

    XCTAssertEqualObjects(self.tagInputView.tags, (@[@"journey", @"house", @"dreamy", @"warm pad"]));
}

- (void)testHashCharactersAreStrippedFromDraftAndCommit {
    self.tagInputView.draftText = @"#Warm #Pad";
    XCTAssertEqualObjects(self.tagInputView.textValue, @"warm pad");

    [self.tagInputView commitDraftText];
    XCTAssertEqualObjects(self.tagInputView.tags, (@[@"warm pad"]));
}

- (void)testHashCharactersAreStrippedFromCommaSeparatedInput {
    [self.tagInputView ingestTextInput:@"#house, #warm pad, jour#ney" commitTrailingToken:YES];
    XCTAssertEqualObjects(self.tagInputView.tags, (@[@"house", @"journey", @"warm pad"]));
}

- (void)testAttachmentCharactersAreStrippedFromNormalizedTags {
    unichar attachmentCharacter = NSAttachmentCharacter;
    NSString *attachmentString = [NSString stringWithCharacters:&attachmentCharacter length:1];
    NSString *rawTag = [NSString stringWithFormat:@"%@%@bad", attachmentString, attachmentString];

    XCTAssertEqualObjects([self.tagInputView normalizedTagFromString:rawTag], @"bad");
}

- (void)testDeleteBackwardRemovesLastTagWhenDraftIsEmpty {
    self.tagInputView.tags = @[@"house", @"warm pad"];
    [self.tagInputView handleDeleteBackwardInEmptyDraft];
    XCTAssertEqualObjects(self.tagInputView.tags, (@[@"house"]));
}

- (void)testDeleteBackwardRemovesTagBeforeCurrentInsertionIndex {
    self.tagInputView.tags = @[@"house", @"warm pad"];
    self.tagInputView.inputInsertionIndex = 1;
    [self.tagInputView handleDeleteBackwardInEmptyDraft];
    XCTAssertEqualObjects(self.tagInputView.tags, (@[@"warm pad"]));
    XCTAssertEqual(self.tagInputView.inputInsertionIndex, 0U);
}

- (void)testEnteringMultipleTagsAndDeletingBackwardRemovesThemAll {
    self.tagInputView.sortsTagsAutomatically = NO;
    [self.tagInputView ingestTextInput:@"house, warm pad, journey, dreamy" commitTrailingToken:YES];
    XCTAssertEqualObjects(self.tagInputView.tags, (@[@"house", @"warm pad", @"journey", @"dreamy"]));

    while (self.tagInputView.tags.count > 0) {
        [self.tagInputView handleDeleteBackwardInEmptyDraft];
    }

    XCTAssertEqualObjects(self.tagInputView.tags, (@[]));
    XCTAssertEqual(self.tagInputView.inputInsertionIndex, 0U);
    XCTAssertEqualObjects(self.tagInputView.textValue, @"");

    [self.tagInputView handleDeleteBackwardInEmptyDraft];
    XCTAssertEqualObjects(self.tagInputView.tags, (@[]));
}

- (void)testReloadSuggestionsQueriesDataSourceAndExcludesSelectedTags {
    TagInputViewSuggestionSource *source = [[TagInputViewSuggestionSource alloc] init];
    source.suggestions = @[@"house", @"warm pad", @"journey"];
    self.tagInputView.tags = @[@"journey"];
    self.tagInputView.dataSource = source;
    self.tagInputView.draftText = @"wa";
    [self.tagInputView reloadSuggestions];
    XCTAssertEqualObjects(source.lastQuery, @"wa");
    XCTAssertEqualObjects(self.tagInputView.resolvedSuggestions, (@[@"warm pad"]));
}

- (void)testReloadSuggestionsClearsSuggestionsForEmptyDraft {
    TagInputViewSuggestionSource *source = [[TagInputViewSuggestionSource alloc] init];
    source.suggestions = @[@"house", @"warm pad", @"journey"];
    self.tagInputView.dataSource = source;
    self.tagInputView.resolvedSuggestions = @[@"stale"];
    self.tagInputView.draftText = @"";

    [self.tagInputView reloadSuggestions];

    XCTAssertEqualObjects(self.tagInputView.resolvedSuggestions, (@[]));
    XCTAssertNil(source.lastQuery);
}

- (void)testAcceptSuggestionCommitsSuggestionAndClearsDraft {
    TagInputViewSuggestionSource *source = [[TagInputViewSuggestionSource alloc] init];
    source.suggestions = @[@"warm pad", @"warm stab"];
    self.tagInputView.dataSource = source;
    self.tagInputView.draftText = @"wa";
    [self.tagInputView reloadSuggestions];
    [self.tagInputView acceptSuggestionAtIndex:1];
    XCTAssertEqualObjects(self.tagInputView.tags, (@[@"warm stab"]));
    XCTAssertEqualObjects(self.tagInputView.textValue, @"");
}

- (void)testSendingActionOnEffectiveTagChange {
    TagInputViewActionTarget *target = [[TagInputViewActionTarget alloc] init];
    self.tagInputView.target = target;
    self.tagInputView.action = @selector(tagInputChanged:);
    self.tagInputView.draftText = @"house";
    [self.tagInputView commitDraftText];
    XCTAssertEqual(target.invocationCount, 1U);
}

- (void)testControlDoesNotExposeIntrinsicHorizontalGrowth {
    NSSize intrinsicSize = self.tagInputView.intrinsicContentSize;
    XCTAssertEqual(intrinsicSize.width, NSViewNoIntrinsicMetric);
    XCTAssertEqual(intrinsicSize.height, 28.0);
}

- (void)testTagInputCanBecomeKeyView {
    XCTAssertTrue(self.tagInputView.acceptsFirstResponder);
    XCTAssertTrue(self.tagInputView.canBecomeKeyView);
}

- (void)testMakingControlFirstResponderStartsEditingTokenField {
    NSWindow *window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 400, 200)
                                                   styleMask:NSWindowStyleMaskTitled
                                                     backing:NSBackingStoreBuffered
                                                       defer:NO];
    self.tagInputView.frame = NSMakeRect(20, 100, 320, 32);
    [window.contentView addSubview:self.tagInputView];

    BOOL becameFirstResponder = [window makeFirstResponder:self.tagInputView];

    XCTAssertTrue(becameFirstResponder);
    XCTAssertNotNil(self.tagInputView.tokenField.currentEditor);
}

- (void)testTokenFieldIsConfiguredAsSingleLineScrollingField {
    NSTextFieldCell *cell = (NSTextFieldCell *)self.tagInputView.tokenField.cell;
    XCTAssertFalse(cell.wraps);
    XCTAssertTrue(cell.scrollable);
    XCTAssertTrue(cell.usesSingleLineMode);
}

- (void)testTokenFieldHasAccessibilityIdentifierForUITests {
    XCTAssertEqualObjects(self.tagInputView.tokenField.accessibilityIdentifier, @"tag-input-editor");
}

- (void)testSettingTextColorUpdatesNativeTokenField {
    self.tagInputView.textColor = NSColor.systemRedColor;
    XCTAssertEqualObjects(self.tagInputView.tokenField.textColor, NSColor.systemRedColor);
}

- (void)testSettingFontUpdatesNativeTokenField {
    NSFont *font = [NSFont boldSystemFontOfSize:15.0];
    self.tagInputView.font = font;
    XCTAssertEqualObjects(self.tagInputView.tokenField.font, font);
}

- (void)testSettingControlSizeUpdatesNativeTokenField {
    self.tagInputView.controlSize = NSControlSizeSmall;
    XCTAssertEqual(self.tagInputView.tokenField.controlSize, NSControlSizeSmall);
}

- (void)testSettingBorderAndBezelStylingUpdatesNativeTokenField {
    self.tagInputView.bordered = NO;
    self.tagInputView.bezeled = NO;
    self.tagInputView.bezelStyle = NSTextFieldSquareBezel;
    self.tagInputView.drawsBackground = NO;

    XCTAssertFalse(self.tagInputView.tokenField.isBordered);
    XCTAssertFalse(self.tagInputView.tokenField.isBezeled);
    XCTAssertEqual(self.tagInputView.tokenField.bezelStyle, NSTextFieldSquareBezel);
    XCTAssertFalse(self.tagInputView.tokenField.drawsBackground);
}

- (void)testSettingBackgroundColorUpdatesNativeTokenField {
    self.tagInputView.backgroundColor = NSColor.systemGreenColor;
    XCTAssertEqualObjects(self.tagInputView.tokenField.backgroundColor, NSColor.systemGreenColor);
}

- (void)testSettingFieldBackgroundColorUpdatesNativeTokenField {
    self.tagInputView.fieldBackgroundColor = NSColor.systemYellowColor;
    XCTAssertEqualObjects(self.tagInputView.tokenField.backgroundColor, NSColor.systemYellowColor);
}

- (void)testSettingAlignmentAndPlaceholderUpdatesNativeTokenField {
    self.tagInputView.alignment = NSTextAlignmentCenter;
    self.tagInputView.placeholderString = @"Type tags";

    XCTAssertEqual(self.tagInputView.tokenField.alignment, NSTextAlignmentCenter);
    XCTAssertEqualObjects(self.tagInputView.tokenField.placeholderString, @"Type tags");
}

- (void)testSettingLineBreakModeUpdatesNativeTokenFieldCell {
    self.tagInputView.lineBreakMode = NSLineBreakByTruncatingMiddle;
    XCTAssertEqual(((NSTextFieldCell *)self.tagInputView.tokenField.cell).lineBreakMode, NSLineBreakByTruncatingMiddle);
}

- (void)testSettingTokenFieldSpecificStylingUpdatesNativeTokenField {
    self.tagInputView.tokenStyle = NSTokenStyleNone;
    self.tagInputView.completionDelay = 0.25;
    self.tagInputView.tokenizingCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@";"];

    XCTAssertEqual(self.tagInputView.tokenField.tokenStyle, NSTokenStyleNone);
    XCTAssertEqualWithAccuracy(self.tagInputView.tokenField.completionDelay, 0.25, 0.0001);
    XCTAssertTrue([self.tagInputView.tokenField.tokenizingCharacterSet characterIsMember:';']);
    XCTAssertFalse([self.tagInputView.tokenField.tokenizingCharacterSet characterIsMember:',']);
}

- (void)testDefaultStyleForRepresentedObjectUsesControlTokenStyle {
    self.tagInputView.tokenStyle = NSTokenStyleNone;

    NSTokenStyle tokenStyle = [self.tagInputView tokenField:self.tagInputView.tokenField styleForRepresentedObject:@"house"];

    XCTAssertEqual(tokenStyle, NSTokenStyleNone);
}

- (void)testDelegateCanOverrideStylePerRepresentedTag {
    TagInputViewStyleDelegate *delegate = [[TagInputViewStyleDelegate alloc] init];
    self.tagInputView.delegate = delegate;
    self.tagInputView.tokenStyle = NSTokenStyleRounded;

    XCTAssertEqual([self.tagInputView tokenField:self.tagInputView.tokenField styleForRepresentedObject:@"featured"], NSTokenStyleSquared);
    XCTAssertEqual([self.tagInputView tokenField:self.tagInputView.tokenField styleForRepresentedObject:@"house"], NSTokenStyleNone);
}

- (void)testEnterWithEmptyDraftDoesNotCommitSuggestion {
    NSTextView *textView = [[NSTextView alloc] initWithFrame:NSZeroRect];
    textView.string = @"";
    BOOL handled = [self.tagInputView control:self.tagInputView.tokenField textView:textView doCommandBySelector:@selector(insertNewline:)];

    XCTAssertFalse(handled);
    XCTAssertEqualObjects(self.tagInputView.tags, (@[]));
}

- (void)testTabWithDraftCommitsTagAndConsumesCommand {
    NSTextView *textView = [[NSTextView alloc] initWithFrame:NSZeroRect];
    textView.string = @"bad";
    self.tagInputView.draftText = @"bad";

    BOOL handled = [self.tagInputView control:self.tagInputView.tokenField textView:textView doCommandBySelector:@selector(insertTab:)];

    XCTAssertTrue(handled);
    XCTAssertEqualObjects(self.tagInputView.tags, (@[@"bad"]));
    XCTAssertEqualObjects(self.tagInputView.textValue, @"");
}

- (void)testTabWithEmptyDraftDoesNotConsumeCommand {
    NSTextView *textView = [[NSTextView alloc] initWithFrame:NSZeroRect];
    textView.string = @"";

    BOOL handled = [self.tagInputView control:self.tagInputView.tokenField textView:textView doCommandBySelector:@selector(insertTab:)];

    XCTAssertFalse(handled);
}

- (void)testTabIgnoringFieldEditorWithDraftCommitsTagAndConsumesCommand {
    NSTextView *textView = [[NSTextView alloc] initWithFrame:NSZeroRect];
    textView.string = @"bad";
    self.tagInputView.draftText = @"bad";

    BOOL handled = [self.tagInputView control:self.tagInputView.tokenField textView:textView doCommandBySelector:@selector(insertTabIgnoringFieldEditor:)];

    XCTAssertTrue(handled);
    XCTAssertEqualObjects(self.tagInputView.tags, (@[@"bad"]));
    XCTAssertEqualObjects(self.tagInputView.textValue, @"");
}

- (void)testTokenFieldRejectsDuplicateObjectsAgainstExistingTags {
    self.tagInputView.tags = @[@"bad"];

    NSArray *acceptedObjects = [self.tagInputView acceptedNormalizedTokensFromObjects:@[@"bad", @" bad"] existingTags:self.tagInputView.tags];

    XCTAssertEqualObjects(acceptedObjects, (@[]));
}

- (void)testTokenFieldRejectsNativeDisambiguationVariantsOfExistingTags {
    self.tagInputView.tags = @[@"bad"];

    NSArray *acceptedObjects = [self.tagInputView acceptedNormalizedTokensFromObjects:@[@" bad", @". bad"] existingTags:self.tagInputView.tags];

    XCTAssertEqualObjects(acceptedObjects, (@[]));
}

- (void)testSyncTagsFromTokenFieldCollapsesDisambiguationVariants {
    self.tagInputView.tokenField.objectValue = @[@"bad", @" bad", @". bad", @"bad"];

    [self.tagInputView syncTagsFromTokenFieldCommitted:NO];

    XCTAssertEqualObjects(self.tagInputView.tags, (@[@"bad"]));
}

- (void)testSyncTagsFromTokenFieldStripsAttachmentCharactersFromExistingObjectValues {
    unichar attachmentCharacter = NSAttachmentCharacter;
    NSString *attachmentString = [NSString stringWithCharacters:&attachmentCharacter length:1];
    NSString *attachmentPrefixedBad = [NSString stringWithFormat:@"%@%@bad", attachmentString, attachmentString];
    self.tagInputView.tokenField.objectValue = @[attachmentPrefixedBad, @"journey", @"warm pad", @"bad"];

    [self.tagInputView syncTagsFromTokenFieldCommitted:NO];

    XCTAssertEqualObjects(self.tagInputView.tags, (@[@"bad", @"journey", @"warm pad"]));
}

- (void)testSyncDraftFromEditorUsesDraftWithoutAttachmentCharacters {
    NSTextView *textView = [[NSTextView alloc] initWithFrame:NSZeroRect];
    unichar attachmentCharacter = NSAttachmentCharacter;
    NSString *attachmentString = [NSString stringWithCharacters:&attachmentCharacter length:1];
    textView.string = [NSString stringWithFormat:@"%@%@%@bad", attachmentString, attachmentString, attachmentString];
    textView.selectedRange = NSMakeRange(textView.string.length, 0);

    [self.tagInputView syncDraftFromEditor:textView];

    XCTAssertEqualObjects(self.tagInputView.textValue, @"bad");
    XCTAssertEqualObjects(textView.string, ([NSString stringWithFormat:@"%@%@%@bad", attachmentString, attachmentString, attachmentString]));
}

- (void)testTokenFieldRejectsDuplicateObjectsWithinSameBatch {
    NSArray *acceptedObjects = [self.tagInputView acceptedNormalizedTokensFromObjects:@[@"bad", @"bad", @" bad"] existingTags:@[]];

    XCTAssertEqualObjects(acceptedObjects, (@[@"bad"]));
}

- (void)testShouldAddObjectsDoesNotRewriteActiveEditorString {
    NSWindow *window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 400, 200)
                                                   styleMask:NSWindowStyleMaskTitled
                                                     backing:NSBackingStoreBuffered
                                                       defer:NO];
    self.tagInputView.frame = NSMakeRect(20, 100, 320, 32);
    [window.contentView addSubview:self.tagInputView];
    [window makeFirstResponder:self.tagInputView];

    NSTextView *textView = (NSTextView *)self.tagInputView.tokenField.currentEditor;
    textView.string = @"house";
    textView.selectedRange = NSMakeRange(textView.string.length, 0);
    self.tagInputView.draftText = @"house";

    NSArray *acceptedObjects = [self.tagInputView tokenField:self.tagInputView.tokenField
                                            shouldAddObjects:@[@"house"]
                                                     atIndex:0];

    XCTAssertEqualObjects(acceptedObjects, (@[@"house"]));
    XCTAssertEqualObjects(textView.string, @"house");
    XCTAssertEqualObjects(self.tagInputView.textValue, @"");
}

- (void)testCollapseEditorSelectionToInsertionPointClearsFullSelection {
    NSWindow *window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 400, 200)
                                                   styleMask:NSWindowStyleMaskTitled
                                                     backing:NSBackingStoreBuffered
                                                       defer:NO];
    self.tagInputView.frame = NSMakeRect(20, 100, 320, 32);
    [window.contentView addSubview:self.tagInputView];
    [window makeFirstResponder:self.tagInputView];

    NSTextView *textView = (NSTextView *)self.tagInputView.tokenField.currentEditor;
    textView.string = @"bad";
    textView.selectedRange = NSMakeRange(0, textView.string.length);

    [self.tagInputView collapseEditorSelectionToInsertionPoint];

    XCTAssertEqual(textView.selectedRange.location, 3U);
    XCTAssertEqual(textView.selectedRange.length, 0U);
}

- (void)testCommitDraftTextSchedulesSelectionCollapseForCommittedPath {
    NSWindow *window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 400, 200)
                                                   styleMask:NSWindowStyleMaskTitled
                                                     backing:NSBackingStoreBuffered
                                                       defer:NO];
    self.tagInputView.frame = NSMakeRect(20, 100, 320, 32);
    [window.contentView addSubview:self.tagInputView];
    [window makeFirstResponder:self.tagInputView];

    NSTextView *textView = (NSTextView *)self.tagInputView.tokenField.currentEditor;
    textView.string = @"bad";
    textView.selectedRange = NSMakeRange(0, textView.string.length);
    self.tagInputView.draftText = @"bad";

    [self.tagInputView commitDraftText];

    XCTestExpectation *expectation = [self expectationWithDescription:@"selection collapsed"];
    dispatch_async(dispatch_get_main_queue(), ^{
        XCTAssertEqual(textView.selectedRange.length, 0U);
        [expectation fulfill];
    });
    [self waitForExpectations:@[expectation] timeout:1.0];
}

@end
