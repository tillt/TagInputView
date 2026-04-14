//
//  TagInputView.h
//
//  Tag Editor Input View.
//
//  Created by Till Toenshoff on 04-14-26.
//  Copyright © 2026 Till Toenshoff. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@class TagInputView;

/**
 Provides synchronous completion results for a tag input view.
 */
@protocol TagInputViewDataSource <NSObject>
@optional

/**
 Returns suggested tags for the current draft query.

 @param view The tag input view requesting suggestions.
 @param query The normalized draft query currently being edited.
 @return An array of suggested tag strings. Return an empty array to provide no suggestions.
 */
- (NSArray<NSString *> *)tagInputView:(TagInputView *)view suggestionsForQuery:(NSString *)query;
@end

/**
 Receives validation and lifecycle callbacks from a tag input view.
 */
@protocol TagInputViewDelegate <NSObject>
@optional

/**
 Normalizes a full candidate tag array before the control adopts it.

 @param view The tag input view requesting normalization.
 @param tags The full candidate tag set.
 @return The normalized tag set the control should adopt.
 */
- (NSArray<NSString *> *)tagInputView:(TagInputView *)view normalizeTags:(NSArray<NSString *> *)tags;

/**
 Asks whether a single tag may be added to the control.

 @param view The tag input view requesting validation.
 @param tag The normalized tag that is about to be added.
 @return `YES` to accept the tag, `NO` to reject it.
 */
- (BOOL)tagInputView:(TagInputView *)view shouldAddTag:(NSString *)tag;

/**
 Asks whether a single tag may be removed from the control.

 @param view The tag input view requesting validation.
 @param tag The normalized tag that is about to be removed.
 @return `YES` to allow removal, `NO` to keep the tag.
 */
- (BOOL)tagInputView:(TagInputView *)view shouldRemoveTag:(NSString *)tag;

/**
 Tells the delegate that the effective tag set changed.

 @param view The tag input view whose tags changed.
 */
- (void)tagInputViewDidChangeTags:(TagInputView *)view;

/**
 Tells the delegate that the control committed tags through an explicit commit action.

 @param view The tag input view that committed its tags.
 */
- (void)tagInputViewDidCommitTags:(TagInputView *)view;

/**
 Returns the token style to use for a specific tag.

 Use this to override the control-wide `tokenStyle` for individual represented tags.

 @param view The tag input view requesting the token style.
 @param tag The normalized tag whose token is about to be displayed.
 @return The token style to use for the given tag.
 */
- (NSTokenStyle)tagInputView:(TagInputView *)view tokenStyleForTag:(NSString *)tag;
@end

/**
 A reusable AppKit tag-entry control backed by `NSTokenField`.

 `TagInputView` exposes a plain array-of-strings tag model while handling token display,
 draft editing, normalization hooks, duplicate filtering, suggestion lookup, and common
 keyboard behaviors such as comma/return commit and delete-backward removal.
 */
@interface TagInputView : NSControl

/// The current normalized tag set shown by the control.
@property (nonatomic, copy) NSArray<NSString *> *tags;

/// The current normalized draft text being edited, if any.
@property (nonatomic, copy, readonly) NSString *textValue;

/// The object that provides synchronous completion suggestions.
@property (nonatomic, weak, nullable) id<TagInputViewDataSource> dataSource;

/// The object that receives validation and lifecycle callbacks.
@property (nonatomic, weak, nullable) id<TagInputViewDelegate> delegate;

/// A Boolean value that determines whether the control accepts editing.
@property (nonatomic, getter=isEditable) BOOL editable;

/// A Boolean value that determines whether the underlying field draws a border.
@property (nonatomic, getter=isBordered) BOOL bordered;

/// A Boolean value that determines whether the underlying field draws a bezel.
@property (nonatomic, getter=isBezeled) BOOL bezeled;

/// The bezel style used by the underlying token field.
@property (nonatomic) NSTextFieldBezelStyle bezelStyle;

/// A Boolean value that determines whether the underlying field draws its background.
@property (nonatomic) BOOL drawsBackground;

/// The background color used by the underlying token field.
@property (nonatomic, copy, null_resettable) NSColor *backgroundColor;

/// The text color used for both draft editing and token text.
@property (nonatomic, copy, nullable) NSColor *textColor;

/// The placeholder string shown when the control is empty and not editing.
@property (nonatomic, copy, nullable) NSString *placeholderString;

/// A convenience alias for `backgroundColor`.
@property (nonatomic, copy, nullable) NSColor *fieldBackgroundColor;

/// The default token style used for represented tags.
@property (nonatomic) NSTokenStyle tokenStyle;

/// The completion delay used by the underlying token field.
@property (nonatomic) NSTimeInterval completionDelay;

/// The character set that commits tokens directly through native tokenization.
@property (nonatomic, copy) NSCharacterSet *tokenizingCharacterSet;

/// A Boolean value that determines whether typing a comma commits the current draft.
@property (nonatomic) BOOL commitsOnComma;

/// A Boolean value that determines whether ending editing auto-commits a non-empty draft.
@property (nonatomic) BOOL commitsOnEndEditing;

/// A Boolean value that determines whether delete-backward on an empty draft removes the previous tag.
@property (nonatomic) BOOL removesLastTagOnDeleteBackward;

/// A Boolean value that determines whether accepted tags are kept in localized standard sort order.
@property (nonatomic) BOOL sortsTagsAutomatically;

/// A Boolean value that determines whether duplicate normalized tags are allowed.
@property (nonatomic) BOOL allowsDuplicateTags;

/**
 Begins editing and places the insertion point at the end of the current draft.
 */
- (void)beginEditing;

/**
 Ends editing and commits the current draft if `commitsOnEndEditing` is enabled.
 */
- (void)endEditingAndCommit;

/**
 Refreshes the current suggestion list for the active draft text.
 */
- (void)reloadSuggestions;

/**
 Reloads the native token field from the current `tags` value.
 */
- (void)reloadData;

@end

NS_ASSUME_NONNULL_END
