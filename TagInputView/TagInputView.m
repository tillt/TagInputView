//
//  TagInputView.m
//
//  Tag Editor Input View.
//
//  Created by Till Toenshoff on 04-14-26.
//  Copyright © 2026 Till Toenshoff. All rights reserved.
//

#import "TagInputView.h"
#import "TagInputView+Private.h"

@interface TagInputView () <NSTokenFieldDelegate, NSTextFieldDelegate>

@property (nonatomic) BOOL suppressCallbacks;

@end

@implementation TagInputView

static const CGFloat kTagInputViewDefaultHeight = 28.0;

static NSString *TagInputAttachmentCharacterString(void) {
    static NSString *attachmentString = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        unichar attachmentCharacter = NSAttachmentCharacter;
        attachmentString = [NSString stringWithCharacters:&attachmentCharacter length:1];
    });
    return attachmentString;
}

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    _tags = @[];
    _draftText = @"";
    _resolvedSuggestions = @[];
    _editable = YES;
    _commitsOnComma = YES;
    _commitsOnEndEditing = YES;
    _removesLastTagOnDeleteBackward = YES;
    _sortsTagsAutomatically = YES;
    _allowsDuplicateTags = NO;
    _inputInsertionIndex = 0;

    [self setContentHuggingPriority:NSLayoutPriorityDefaultLow forOrientation:NSLayoutConstraintOrientationHorizontal];
    [self setContentCompressionResistancePriority:NSLayoutPriorityDefaultLow forOrientation:NSLayoutConstraintOrientationHorizontal];
    [self setContentHuggingPriority:NSLayoutPriorityRequired forOrientation:NSLayoutConstraintOrientationVertical];
    [self setContentCompressionResistancePriority:NSLayoutPriorityRequired forOrientation:NSLayoutConstraintOrientationVertical];

    self.tokenField = [[NSTokenField alloc] initWithFrame:NSZeroRect];
    self.tokenField.translatesAutoresizingMaskIntoConstraints = NO;
    self.tokenField.delegate = self;
    self.tokenField.editable = YES;
    self.tokenField.selectable = YES;
    self.tokenField.bordered = YES;
    self.tokenField.bezeled = YES;
    self.tokenField.bezelStyle = NSTextFieldRoundedBezel;
    self.tokenField.drawsBackground = YES;
    self.tokenField.font = [NSFont systemFontOfSize:13.0];
    self.tokenField.controlSize = NSControlSizeRegular;
    self.tokenField.alignment = NSTextAlignmentLeft;
    self.tokenField.tokenStyle = NSTokenStyleRounded;
    self.tokenField.completionDelay = 0.0;
    self.tokenField.tokenizingCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@","];
    self.tokenField.accessibilityIdentifier = @"tag-input-editor";
    self.tokenField.accessibilityLabel = @"Tag input editor";

    NSTextFieldCell *cell = (NSTextFieldCell *)self.tokenField.cell;
    cell.wraps = NO;
    cell.scrollable = YES;
    cell.usesSingleLineMode = YES;
    cell.lineBreakMode = NSLineBreakByClipping;
    self.tokenField.textColor = NSColor.labelColor;
    self.tokenField.backgroundColor = NSColor.textBackgroundColor;

    [self addSubview:self.tokenField];
    [NSLayoutConstraint activateConstraints:@[
        [self.tokenField.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [self.tokenField.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [self.tokenField.topAnchor constraintEqualToAnchor:self.topAnchor],
        [self.tokenField.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
    ]];
    
    [self reloadData];
}

- (NSCell*)cell {
    return self.tokenField.cell;
}

- (NSSize)intrinsicContentSize {
    return NSMakeSize(NSViewNoIntrinsicMetric, kTagInputViewDefaultHeight);
}

- (NSString *)textValue {
    return self.draftText;
}

- (BOOL)acceptsFirstResponder {
    return self.isEditable;
}

- (BOOL)canBecomeKeyView {
    return self.isEditable && !self.isHidden;
}

- (BOOL)becomeFirstResponder {
    [self beginEditing];
    return YES;
}

- (void)mouseDown:(NSEvent *)event {
    [self beginEditing];
}

- (BOOL)isAccessibilityElement {
    return YES;
}

- (NSString *)accessibilityRole {
    return NSAccessibilityGroupRole;
}

- (NSString *)accessibilityLabel {
    return @"Tag input";
}

- (BOOL)accessibilityPerformPress {
    [self beginEditing];
    return YES;
}

- (void)setEditable:(BOOL)editable {
    _editable = editable;
    self.tokenField.editable = editable;
    self.tokenField.selectable = editable;
}

- (NSFont *)font {
    return self.tokenField.font;
}

- (void)setFont:(NSFont *)font {
    self.tokenField.font = font ?: [NSFont systemFontOfSize:13.0];
}

- (NSControlSize)controlSize {
    return self.tokenField.controlSize;
}

- (void)setControlSize:(NSControlSize)controlSize {
    self.tokenField.controlSize = controlSize;
}

- (BOOL)isBordered {
    return self.tokenField.isBordered;
}

- (void)setBordered:(BOOL)bordered {
    self.tokenField.bordered = bordered;
}

- (BOOL)isBezeled {
    return self.tokenField.isBezeled;
}

- (void)setBezeled:(BOOL)bezeled {
    self.tokenField.bezeled = bezeled;
}

- (NSTextFieldBezelStyle)bezelStyle {
    return self.tokenField.bezelStyle;
}

- (void)setBezelStyle:(NSTextFieldBezelStyle)bezelStyle {
    self.tokenField.bezelStyle = bezelStyle;
}

- (BOOL)drawsBackground {
    return self.tokenField.drawsBackground;
}

- (void)setDrawsBackground:(BOOL)drawsBackground {
    self.tokenField.drawsBackground = drawsBackground;
}

- (NSColor *)backgroundColor {
    return self.tokenField.backgroundColor ?: NSColor.textBackgroundColor;
}

- (void)setBackgroundColor:(NSColor *)backgroundColor {
    self.tokenField.backgroundColor = backgroundColor ?: NSColor.textBackgroundColor;
}

- (void)setTextColor:(NSColor *)textColor {
    self.tokenField.textColor = [textColor copy] ?: NSColor.labelColor;
}

- (NSColor *)textColor {
    return self.tokenField.textColor ?: NSColor.labelColor;
}

- (NSTextAlignment)alignment {
    return self.tokenField.alignment;
}

- (void)setAlignment:(NSTextAlignment)alignment {
    self.tokenField.alignment = alignment;
}

- (NSString *)placeholderString {
    return self.tokenField.placeholderString;
}

- (void)setPlaceholderString:(NSString *)placeholderString {
    self.tokenField.placeholderString = [placeholderString copy];
}

- (NSLineBreakMode)lineBreakMode {
    return ((NSTextFieldCell *)self.tokenField.cell).lineBreakMode;
}

- (void)setLineBreakMode:(NSLineBreakMode)lineBreakMode {
    ((NSTextFieldCell *)self.tokenField.cell).lineBreakMode = lineBreakMode;
}

- (void)setFieldBackgroundColor:(NSColor *)fieldBackgroundColor {
    self.backgroundColor = fieldBackgroundColor;
}

- (NSColor *)fieldBackgroundColor {
    return self.backgroundColor;
}

- (NSTokenStyle)tokenStyle {
    return self.tokenField.tokenStyle;
}

- (void)setTokenStyle:(NSTokenStyle)tokenStyle {
    self.tokenField.tokenStyle = tokenStyle;
}

- (NSTimeInterval)completionDelay {
    return self.tokenField.completionDelay;
}

- (void)setCompletionDelay:(NSTimeInterval)completionDelay {
    self.tokenField.completionDelay = completionDelay;
}

- (NSCharacterSet *)tokenizingCharacterSet {
    return self.tokenField.tokenizingCharacterSet ?: [NSCharacterSet characterSetWithCharactersInString:@","];
}

- (void)setTokenizingCharacterSet:(NSCharacterSet *)tokenizingCharacterSet {
    self.tokenField.tokenizingCharacterSet = [tokenizingCharacterSet copy] ?: [NSCharacterSet characterSetWithCharactersInString:@","];
}

- (void)setTags:(NSArray<NSString *> *)tags {
    NSArray<NSString *> *normalizedTags = [self normalizedTagsFromArray:tags];
    if ([_tags isEqualToArray:normalizedTags]) {
        return;
    }

    _tags = [normalizedTags copy];
    self.inputInsertionIndex = _tags.count;
    [self reloadData];
}

- (void)setDraftText:(NSString *)draftText {
    _draftText = [self sanitizedUserInputString:draftText ?: @""];
}

- (void)beginEditing {
    if (self.window == nil) {
        return;
    }

    [self.window makeFirstResponder:self.tokenField];
    NSText *currentEditor = [self.window fieldEditor:NO forObject:self.tokenField];
    if ([currentEditor isKindOfClass:[NSTextView class]]) {
        NSTextView *textView = (NSTextView *)currentEditor;
        textView.string = self.draftText ?: @"";
        textView.selectedRange = NSMakeRange(textView.string.length, 0);
    }
}

- (void)endEditingAndCommit {
    if (self.commitsOnEndEditing) {
        [self commitDraftText];
    }
}

- (void)reloadData {
    self.suppressCallbacks = YES;
    self.tokenField.objectValue = self.tags;
    self.tokenField.editable = self.isEditable;
    self.tokenField.selectable = self.isEditable;
    self.suppressCallbacks = NO;
}

- (void)reloadSuggestions {
    self.resolvedSuggestions = [self orderedSuggestionsForQuery:self.draftText];
}

- (void)collapseEditorSelectionToInsertionPoint {
    NSText *currentEditor = self.tokenField.currentEditor;
    if (![currentEditor isKindOfClass:[NSTextView class]]) {
        return;
    }

    NSTextView *textView = (NSTextView *)currentEditor;
    NSUInteger insertionLocation = MIN(textView.selectedRange.location + textView.selectedRange.length, textView.string.length);
    textView.selectedRange = NSMakeRange(insertionLocation, 0);
}

- (void)scheduleCommittedSelectionCollapse {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSText *currentEditor = self.tokenField.currentEditor;
        if (![currentEditor isKindOfClass:[NSTextView class]]) {
            return;
        }

        NSTextView *textView = (NSTextView *)currentEditor;
        if (textView.selectedRange.length > 0) {
            [textView moveRight:nil];
        }
        [self collapseEditorSelectionToInsertionPoint];
    });
}

- (void)commitDraftText {
    NSString *normalizedDraft = [self normalizedTagFromString:self.draftText];
    self.draftText = @"";
    if (normalizedDraft.length == 0) {
        [self reloadSuggestions];
        return;
    }

    if ([self.delegate respondsToSelector:@selector(tagInputView:shouldAddTag:)] &&
        ![self.delegate tagInputView:self shouldAddTag:normalizedDraft]) {
        [self reloadSuggestions];
        return;
    }

    NSMutableArray<NSString *> *candidateTags = [self.tags mutableCopy];
    NSUInteger insertionIndex = MIN(self.inputInsertionIndex, candidateTags.count);
    [candidateTags insertObject:normalizedDraft atIndex:insertionIndex];
    [self applyCandidateTags:candidateTags committed:YES];
}

- (void)commitCurrentDraftPreferringSuggestionSelection {
    if (self.draftText.length == 0) {
        return;
    }

    NSInteger selectedIndex = 0;
    NSArray<NSString *> *suggestions = [self tokenField:self.tokenField
                               completionsForSubstring:self.draftText
                                          indexOfToken:self.tags.count
                                    indexOfSelectedItem:&selectedIndex];
    if (suggestions.count > 0 && selectedIndex >= 0 && selectedIndex < (NSInteger)suggestions.count) {
        self.draftText = suggestions[(NSUInteger)selectedIndex];
    }
    [self commitDraftText];
}

- (void)ingestTextInput:(NSString *)text commitTrailingToken:(BOOL)commitTrailingToken {
    NSString *composedText = [self sanitizedUserInputString:text ?: @""];
    if (self.draftText.length > 0) {
        composedText = [self.draftText stringByAppendingString:composedText];
    }

    NSArray<NSString *> *segments = [composedText componentsSeparatedByString:@","];
    NSMutableArray<NSString *> *candidateTags = [self.tags mutableCopy];
    NSUInteger committedCount = commitTrailingToken ? segments.count : MAX((NSInteger)segments.count - 1, 0);
    NSUInteger insertionIndex = MIN(self.inputInsertionIndex, candidateTags.count);

    for (NSUInteger index = 0; index < committedCount; index++) {
        NSString *normalizedTag = [self normalizedTagFromString:segments[index]];
        if (normalizedTag.length == 0) {
            continue;
        }

        if ([self.delegate respondsToSelector:@selector(tagInputView:shouldAddTag:)] &&
            ![self.delegate tagInputView:self shouldAddTag:normalizedTag]) {
            continue;
        }

        [candidateTags insertObject:normalizedTag atIndex:insertionIndex];
        insertionIndex += 1;
    }

    self.draftText = commitTrailingToken ? @"" : [segments.lastObject stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    [self applyCandidateTags:candidateTags committed:YES];
}

- (void)handleDeleteBackwardInEmptyDraft {
    if (!self.removesLastTagOnDeleteBackward || self.draftText.length > 0 || self.tags.count == 0) {
        return;
    }

    NSUInteger insertionIndex = MIN(self.inputInsertionIndex, self.tags.count);
    if (insertionIndex == 0) {
        return;
    }

    NSUInteger removalIndex = insertionIndex - 1;
    NSString *tag = self.tags[removalIndex];
    if ([self.delegate respondsToSelector:@selector(tagInputView:shouldRemoveTag:)] &&
        ![self.delegate tagInputView:self shouldRemoveTag:tag]) {
        return;
    }

    NSMutableArray<NSString *> *candidateTags = [self.tags mutableCopy];
    [candidateTags removeObjectAtIndex:removalIndex];
    self.inputInsertionIndex = removalIndex;
    [self applyCandidateTags:candidateTags committed:NO];
}

- (void)acceptSuggestionAtIndex:(NSInteger)index {
    if (index < 0 || index >= (NSInteger)self.resolvedSuggestions.count) {
        return;
    }

    self.draftText = self.resolvedSuggestions[(NSUInteger)index];
    [self commitDraftText];
}

- (NSArray<NSString *> *)orderedSuggestionsForQuery:(NSString *)queryString {
    NSString *query = [self normalizedTagFromString:queryString];
    if (query.length == 0) {
        return @[];
    }

    NSArray<NSString *> *suggestions = @[];
    if ([self.dataSource respondsToSelector:@selector(tagInputView:suggestionsForQuery:)]) {
        suggestions = [self.dataSource tagInputView:self suggestionsForQuery:query] ?: @[];
    }

    NSMutableOrderedSet<NSString *> *prefixMatches = [NSMutableOrderedSet orderedSet];
    NSMutableOrderedSet<NSString *> *substringMatches = [NSMutableOrderedSet orderedSet];
    NSSet<NSString *> *selectedTags = [NSSet setWithArray:self.tags];

    for (NSString *suggestion in suggestions) {
        NSString *normalizedSuggestion = [self normalizedTagFromString:suggestion];
        if (normalizedSuggestion.length == 0 || [selectedTags containsObject:normalizedSuggestion]) {
            continue;
        }

        NSRange queryRange = [normalizedSuggestion rangeOfString:query options:NSCaseInsensitiveSearch];
        if (queryRange.location == NSNotFound) {
            continue;
        }

        if (queryRange.location == 0) {
            [prefixMatches addObject:normalizedSuggestion];
        } else {
            [substringMatches addObject:normalizedSuggestion];
        }
    }

    NSMutableArray<NSString *> *orderedSuggestions = [NSMutableArray arrayWithArray:prefixMatches.array];
    [orderedSuggestions addObjectsFromArray:substringMatches.array];
    return orderedSuggestions;
}

- (NSArray<NSString *> *)normalizedTagsFromArray:(NSArray<NSString *> *)tags {
    if ([self.delegate respondsToSelector:@selector(tagInputView:normalizeTags:)]) {
        return [self.delegate tagInputView:self normalizeTags:tags] ?: @[];
    }

    NSMutableOrderedSet<NSString *> *normalizedTags = [NSMutableOrderedSet orderedSet];
    for (NSString *tag in tags) {
        NSString *normalizedTag = [self normalizedTagFromString:tag];
        if (normalizedTag.length == 0) {
            continue;
        }

        NSString *dedisambiguatedTag = [self dedisambiguatedTagCandidateFromNormalizedTag:normalizedTag];
        BOOL isDuplicateDisambiguationVariant = !self.allowsDuplicateTags &&
            ![dedisambiguatedTag isEqualToString:normalizedTag] &&
            [normalizedTags containsObject:dedisambiguatedTag];

        if ((self.allowsDuplicateTags || ![normalizedTags containsObject:normalizedTag]) &&
            !isDuplicateDisambiguationVariant) {
            [normalizedTags addObject:normalizedTag];
        }
    }

    NSArray<NSString *> *result = normalizedTags.array;
    if (self.sortsTagsAutomatically) {
        result = [result sortedArrayUsingSelector:@selector(localizedStandardCompare:)];
    }
    return result;
}

- (NSArray<NSString *> *)acceptedNormalizedTokensFromObjects:(NSArray *)tokens
                                              existingTags:(NSArray<NSString *> *)existingTags {
    NSMutableArray<NSString *> *acceptedTokens = [NSMutableArray array];
    NSMutableOrderedSet<NSString *> *seenTags = [NSMutableOrderedSet orderedSetWithArray:existingTags ?: @[]];

    for (id token in tokens) {
        NSString *normalizedTag = [self normalizedTagFromString:[token isKindOfClass:[NSString class]] ? token : [token description]];
        if (normalizedTag.length == 0) {
            continue;
        }

        NSString *dedisambiguatedTag = [self dedisambiguatedTagCandidateFromNormalizedTag:normalizedTag];

        if (!self.allowsDuplicateTags &&
            ([seenTags containsObject:normalizedTag] || [seenTags containsObject:dedisambiguatedTag])) {
            continue;
        }

        if ([self.delegate respondsToSelector:@selector(tagInputView:shouldAddTag:)] &&
            ![self.delegate tagInputView:self shouldAddTag:normalizedTag]) {
            continue;
        }

        [acceptedTokens addObject:normalizedTag];
        if (!self.allowsDuplicateTags) {
            [seenTags addObject:normalizedTag];
            if (![dedisambiguatedTag isEqualToString:normalizedTag]) {
                [seenTags addObject:dedisambiguatedTag];
            }
        }
    }

    return acceptedTokens;
}

- (NSString *)normalizedTagFromString:(NSString *)tag {
    NSString *normalizedTag = [[self sanitizedUserInputString:tag ?: @""] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return normalizedTag ?: @"";
}

- (NSString *)dedisambiguatedTagCandidateFromNormalizedTag:(NSString *)normalizedTag {
    NSMutableCharacterSet *prefixCharacterSet = [[NSCharacterSet whitespaceAndNewlineCharacterSet] mutableCopy];
    [prefixCharacterSet formUnionWithCharacterSet:[NSCharacterSet punctuationCharacterSet]];

    NSString *candidateTag = normalizedTag ?: @"";
    while (candidateTag.length > 0 && [prefixCharacterSet characterIsMember:[candidateTag characterAtIndex:0]]) {
        candidateTag = [[candidateTag substringFromIndex:1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }

    return candidateTag.length > 0 ? candidateTag : normalizedTag;
}

- (NSString *)sanitizedUserInputString:(NSString *)string {
    NSString *sanitizedString = [string stringByReplacingOccurrencesOfString:@"#" withString:@""];
    sanitizedString = [sanitizedString stringByReplacingOccurrencesOfString:TagInputAttachmentCharacterString() withString:@""];
    return sanitizedString.lowercaseString;
}

- (void)notifyObserversForCommittedChange:(BOOL)committed tagsChanged:(BOOL)tagsChanged {
    if (tagsChanged && !self.suppressCallbacks) {
        if ([self.delegate respondsToSelector:@selector(tagInputViewDidChangeTags:)]) {
            [self.delegate tagInputViewDidChangeTags:self];
        }
        [self sendAction:self.action to:self.target];
    }

    if (committed && [self.delegate respondsToSelector:@selector(tagInputViewDidCommitTags:)]) {
        [self.delegate tagInputViewDidCommitTags:self];
    }
}

- (void)applyCandidateTags:(NSArray<NSString *> *)candidateTags committed:(BOOL)committed {
    NSArray<NSString *> *normalizedTags = [self normalizedTagsFromArray:candidateTags];
    BOOL tagsChanged = ![self.tags isEqualToArray:normalizedTags];

    _tags = [normalizedTags copy];
    self.inputInsertionIndex = committed ? self.tags.count : MIN(self.inputInsertionIndex, self.tags.count);
    [self reloadData];
    if (committed) {
        [self scheduleCommittedSelectionCollapse];
    }
    [self reloadSuggestions];

    [self notifyObserversForCommittedChange:committed tagsChanged:tagsChanged];
}

- (void)syncDraftFromEditor:(NSTextView *)textView {
    NSString *editorString = textView.string ?: @"";
    NSString *sanitizedDraft = [self sanitizedUserInputString:editorString];
    BOOL containsAttachmentCharacters = [editorString rangeOfString:TagInputAttachmentCharacterString()].location != NSNotFound;
    if (!containsAttachmentCharacters && ![sanitizedDraft isEqualToString:editorString]) {
        NSRange selectedRange = textView.selectedRange;
        textView.string = sanitizedDraft;
        NSUInteger clampedLocation = MIN(selectedRange.location, sanitizedDraft.length);
        textView.selectedRange = NSMakeRange(clampedLocation, 0);
    }
    _draftText = sanitizedDraft;
}

- (void)syncTagsFromTokenFieldCommitted:(BOOL)committed {
    NSArray *objectValue = [self.tokenField.objectValue isKindOfClass:[NSArray class]] ? self.tokenField.objectValue : @[];
    NSArray<NSString *> *normalizedTags = [self normalizedTagsFromArray:objectValue];
    if ([self.tags isEqualToArray:normalizedTags]) {
        return;
    }

    BOOL tagsChanged = ![self.tags isEqualToArray:normalizedTags];
    _tags = [normalizedTags copy];
    self.inputInsertionIndex = self.tags.count;
    [self reloadData];
    if (committed) {
        [self scheduleCommittedSelectionCollapse];
    }

    [self notifyObserversForCommittedChange:committed tagsChanged:tagsChanged];
}

#pragma mark - NSTextFieldDelegate

- (void)controlTextDidBeginEditing:(NSNotification *)notification {
    NSText *editor = self.tokenField.currentEditor;
    if ([editor isKindOfClass:[NSTextView class]]) {
        [self syncDraftFromEditor:(NSTextView *)editor];
    }
    [self reloadSuggestions];
}

- (void)controlTextDidChange:(NSNotification *)notification {
    NSText *editor = self.tokenField.currentEditor;
    if ([editor isKindOfClass:[NSTextView class]]) {
        [self syncDraftFromEditor:(NSTextView *)editor];
    }

    NSArray *objectValue = [self.tokenField.objectValue isKindOfClass:[NSArray class]] ? self.tokenField.objectValue : @[];
    if (self.pendingCommittedTokenSync) {
        self.pendingCommittedTokenSync = NO;
        [self syncTagsFromTokenFieldCommitted:YES];
    } else if (objectValue.count < self.tags.count) {
        [self syncTagsFromTokenFieldCommitted:NO];
    }

    [self reloadSuggestions];
}

- (void)controlTextDidEndEditing:(NSNotification *)notification {
    [self syncTagsFromTokenFieldCommitted:NO];
    if (self.commitsOnEndEditing && self.draftText.length > 0) {
        [self commitDraftText];
    } else {
        self.draftText = @"";
        [self reloadSuggestions];
    }
}

- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector {
    if (commandSelector == @selector(insertNewline:)) {
        if (self.draftText.length == 0) {
            return NO;
        }

        [self commitCurrentDraftPreferringSuggestionSelection];
        return YES;
    }

    if (commandSelector == @selector(insertTab:) ||
        commandSelector == @selector(insertTabIgnoringFieldEditor:)) {
        if (self.draftText.length == 0) {
            return NO;
        }

        [self commitCurrentDraftPreferringSuggestionSelection];
        return YES;
    }

    if (commandSelector == @selector(deleteBackward:) && textView.string.length == 0) {
        [self handleDeleteBackwardInEmptyDraft];
        return YES;
    }

    return NO;
}

#pragma mark - NSTokenFieldDelegate

- (NSArray *)tokenField:(NSTokenField *)tokenField completionsForSubstring:(NSString *)substring indexOfToken:(NSInteger)tokenIndex indexOfSelectedItem:(NSInteger *)selectedIndex {
    self.resolvedSuggestions = [self orderedSuggestionsForQuery:substring];
    if (selectedIndex != NULL) {
        *selectedIndex = self.resolvedSuggestions.count > 0 ? 0 : -1;
    }
    return self.resolvedSuggestions;
}

- (NSArray *)tokenField:(NSTokenField *)tokenField shouldAddObjects:(NSArray *)tokens atIndex:(NSUInteger)index {
    NSArray<NSString *> *acceptedTokens = [self acceptedNormalizedTokensFromObjects:tokens existingTags:self.tags];
    self.pendingCommittedTokenSync = acceptedTokens.count > 0;
    self.draftText = @"";
    return acceptedTokens;
}

- (nullable NSString *)tokenField:(NSTokenField *)tokenField displayStringForRepresentedObject:(id)representedObject {
    return [representedObject isKindOfClass:[NSString class]] ? representedObject : [representedObject description];
}

- (nullable NSString *)tokenField:(NSTokenField *)tokenField editingStringForRepresentedObject:(id)representedObject {
    return [self tokenField:tokenField displayStringForRepresentedObject:representedObject];
}

- (nullable id)tokenField:(NSTokenField *)tokenField representedObjectForEditingString:(NSString *)editingString {
    NSString *normalizedTag = [self normalizedTagFromString:editingString];
    return normalizedTag.length > 0 ? normalizedTag : nil;
}

- (NSTokenStyle)tokenField:(NSTokenField *)tokenField styleForRepresentedObject:(id)representedObject {
    if ([representedObject isKindOfClass:[NSString class]] &&
        [self.delegate respondsToSelector:@selector(tagInputView:tokenStyleForTag:)]) {
        return [self.delegate tagInputView:self tokenStyleForTag:(NSString *)representedObject];
    }

    return self.tokenStyle;
}

@end
