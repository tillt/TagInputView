//
//  AppDelegate.m
//  TagViewPlayground
//
//  Created by Till Toenshoff on 4/13/26.
//

#import "AppDelegate.h"
#import "TagCodec.h"
#import "TagInputView.h"

@interface AppDelegate () <TagInputViewDataSource, TagInputViewDelegate>

@property (strong) IBOutlet NSWindow *window;
@property (strong) TagInputView *tagInputView;
@property (strong) NSTextField *plainTextField;
@property (strong) NSTextField *serializedValueLabel;
@property (copy) NSArray<NSString *> *allKnownTags;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    BOOL launchesForEmptyTagInputUIState = [NSProcessInfo.processInfo.arguments containsObject:@"-TagInputUITestEmptyTags"];
    BOOL disablesSuggestionsForUITests = [NSProcessInfo.processInfo.arguments containsObject:@"-TagInputUITestDisableSuggestions"];

    self.allKnownTags = @[
        @"airy",
        @"bad",
        @"bassline",
        @"broken beat",
        @"deep journey",
        @"dreamy",
        @"dub chords",
        @"harsh bass",
        @"house",
        @"journey",
        @"percussive",
        @"shrieking leads",
        @"warm pad",
    ];
    if (disablesSuggestionsForUITests) {
        self.allKnownTags = @[];
    }

    NSView *contentView = self.window.contentView;
    contentView.wantsLayer = YES;
    contentView.layer.backgroundColor = NSColor.windowBackgroundColor.CGColor;

    NSTextField *headline = [NSTextField labelWithString:@"TagInputView"];
    headline.font = [NSFont systemFontOfSize:20.0 weight:NSFontWeightSemibold];
    headline.translatesAutoresizingMaskIntoConstraints = NO;

    NSTextField *explanation = [NSTextField labelWithString:@"Type tags, use comma or return to commit, and use backspace on empty input to remove the last tag."];
    explanation.font = [NSFont systemFontOfSize:12.5];
    explanation.textColor = NSColor.secondaryLabelColor;
    explanation.translatesAutoresizingMaskIntoConstraints = NO;

    self.tagInputView = [[TagInputView alloc] initWithFrame:NSZeroRect];
    self.tagInputView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tagInputView.accessibilityIdentifier = @"tag-input-view";
    self.tagInputView.accessibilityLabel = @"Tag input";
    self.tagInputView.dataSource = self;
    self.tagInputView.delegate = self;
    self.tagInputView.tags = launchesForEmptyTagInputUIState ? @[] : @[@"journey", @"warm pad"];

    self.plainTextField = [[NSTextField alloc] initWithFrame:NSZeroRect];
    self.plainTextField.translatesAutoresizingMaskIntoConstraints = NO;
    self.plainTextField.accessibilityIdentifier = @"plain-text-field";
    self.plainTextField.placeholderString = @"Plain text field for focus/editing comparison";
    self.plainTextField.font = [NSFont systemFontOfSize:13.0];

    self.serializedValueLabel = [NSTextField labelWithString:@""];
    self.serializedValueLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.serializedValueLabel.accessibilityIdentifier = @"serialized-value-label";
    self.serializedValueLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    self.serializedValueLabel.maximumNumberOfLines = 1;
    self.serializedValueLabel.font = [NSFont monospacedSystemFontOfSize:12.5 weight:NSFontWeightRegular];
    self.serializedValueLabel.textColor = NSColor.secondaryLabelColor;
    self.serializedValueLabel.cell.wraps = NO;
    self.serializedValueLabel.cell.scrollable = NO;
    self.serializedValueLabel.cell.usesSingleLineMode = YES;
    [self.serializedValueLabel setContentHuggingPriority:NSLayoutPriorityDefaultLow forOrientation:NSLayoutConstraintOrientationHorizontal];
    [self.serializedValueLabel setContentCompressionResistancePriority:NSLayoutPriorityDefaultLow forOrientation:NSLayoutConstraintOrientationHorizontal];

    NSStackView *stackView = [[NSStackView alloc] initWithFrame:NSZeroRect];
    stackView.translatesAutoresizingMaskIntoConstraints = NO;
    stackView.orientation = NSUserInterfaceLayoutOrientationVertical;
    stackView.alignment = NSLayoutAttributeLeading;
    stackView.spacing = 12.0;
    [stackView addArrangedSubview:headline];
    [stackView addArrangedSubview:explanation];
    [stackView addArrangedSubview:self.tagInputView];
    [stackView addArrangedSubview:self.plainTextField];
    [stackView addArrangedSubview:self.serializedValueLabel];
    [contentView addSubview:stackView];

    [NSLayoutConstraint activateConstraints:@[
        [stackView.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor constant:24.0],
        [stackView.trailingAnchor constraintEqualToAnchor:contentView.trailingAnchor constant:-24.0],
        [stackView.topAnchor constraintEqualToAnchor:contentView.topAnchor constant:24.0],
        [self.tagInputView.widthAnchor constraintEqualToAnchor:stackView.widthAnchor],
        [self.tagInputView.heightAnchor constraintEqualToConstant:28.0],
        [self.plainTextField.widthAnchor constraintEqualToAnchor:stackView.widthAnchor],
        [self.serializedValueLabel.widthAnchor constraintEqualToAnchor:stackView.widthAnchor],
    ]];

    [self updateSerializedValueLabel];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app {
    return YES;
}

- (NSArray<NSString *> *)tagInputView:(TagInputView *)view suggestionsForQuery:(NSString *)query {
    if (query.length == 0) {
        return self.allKnownTags;
    }

    return [self.allKnownTags filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSString *tag, NSDictionary<NSString *,id> * _Nullable bindings) {
        return [tag rangeOfString:query options:NSCaseInsensitiveSearch].location != NSNotFound;
    }]];
}

- (void)tagInputViewDidChangeTags:(TagInputView *)view {
    [self updateSerializedValueLabel];
}

- (void)updateSerializedValueLabel {
    NSString *serializedValue = [TagCodec hashtagStringFromTags:self.tagInputView.tags];
    self.serializedValueLabel.stringValue = serializedValue.length > 0 ? serializedValue : @"#";
}


@end
