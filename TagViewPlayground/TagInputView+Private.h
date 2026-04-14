//
//  TagInputView+Private.h
//
//  Tag Editor Input View.
//
//  Created by Till Toenshoff on 04-14-26.
//  Copyright © 2026 Till Toenshoff. All rights reserved.
//

#import "TagInputView.h"

NS_ASSUME_NONNULL_BEGIN

@interface TagInputView ()

@property (nonatomic, copy) NSString *draftText;
@property (nonatomic, copy) NSArray<NSString *> *resolvedSuggestions;
@property (nonatomic, strong) NSTokenField *tokenField;
@property (nonatomic) NSUInteger inputInsertionIndex;
@property (nonatomic) BOOL pendingCommittedTokenSync;

- (void)commitDraftText;
- (void)commitCurrentDraftPreferringSuggestionSelection;
- (void)ingestTextInput:(NSString *)text commitTrailingToken:(BOOL)commitTrailingToken;
- (void)handleDeleteBackwardInEmptyDraft;
- (void)acceptSuggestionAtIndex:(NSInteger)index;
- (NSArray<NSString *> *)acceptedNormalizedTokensFromObjects:(NSArray *)tokens existingTags:(NSArray<NSString *> *)existingTags;
- (NSString *)normalizedTagFromString:(NSString *)tag;
- (NSString *)dedisambiguatedTagCandidateFromNormalizedTag:(NSString *)normalizedTag;
- (void)collapseEditorSelectionToInsertionPoint;
- (void)scheduleCommittedSelectionCollapse;
- (void)syncDraftFromEditor:(NSTextView *)textView;
- (void)syncTagsFromTokenFieldCommitted:(BOOL)committed;
- (NSArray *)tokenField:(NSTokenField *)tokenField shouldAddObjects:(NSArray *)tokens atIndex:(NSUInteger)index;
- (NSTokenStyle)tokenField:(NSTokenField *)tokenField styleForRepresentedObject:(id)representedObject;
- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector;

@end

NS_ASSUME_NONNULL_END
