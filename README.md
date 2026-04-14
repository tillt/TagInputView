# TagInputView

`TagInputView` is a reusable AppKit tag-entry control backed by `NSTokenField`.

It provides:

- plain `NSArray<NSString *> *` tag values
- synchronous suggestions
- duplicate filtering
- keyboard-first editing
- hashtag storage conversion through `TagCodec`

## Components

- `TagInputView`
  - the reusable control
- `TagCodec`
  - converts between plain tags and `#tag #tag` storage strings
- `TagViewPlayground`
  - a small macOS host app for interaction and styling tests

## Behavior

- multi-word tags
- `,`, `Return`, and `Tab` commit tags
- delete-backward on an empty draft removes the previous tag
- tags normalize to lowercase, trimmed strings
- `#` and token attachment marker characters are stripped
- duplicates are rejected by default

## API

Main value surface:

- `tags`
- `textValue`
- `dataSource`
- `delegate`

Main behavior options:

- `commitsOnComma`
- `commitsOnEndEditing`
- `removesLastTagOnDeleteBackward`
- `sortsTagsAutomatically`
- `allowsDuplicateTags`

Per-tag token styling is available through:

```objc
- (NSTokenStyle)tagInputView:(TagInputView *)view tokenStyleForTag:(NSString *)tag;
```

## Codec

```objc
NSArray<NSString *> *tags = [TagCodec tagsFromHashtagString:string];
NSString *string = [TagCodec hashtagStringFromTags:tags];
```

Example:

```text
#house #warm pad #journey
```
