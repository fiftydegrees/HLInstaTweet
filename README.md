# HLInstaTweet

Lightweight Objective-C component handling all the Twitter publish actions on iOS. Easily share a full-text status or a photo in a single line of code.

![HLInstaTweet Sample](https://raw.githubusercontent.com/fiftydegrees/HLInstaTweet/master/README-Files/hlinstatweet-sample.png)

![HLInstaTweet Account picker](https://raw.githubusercontent.com/fiftydegrees/HLInstaTweet/master/README-Files/hlinstatweet-accountpicker.gif)

## Installation

_**If your project doesn't use ARC**: you must add the `-fobjc-arc` compiler flag to `HLInstaTweet.m` in Target Settings > Build Phases > Compile Sources._

* Simply drag the `./HLInstaTweet` folder into your project.

## Usage

You must use `[HLInstaTweet sharedInstaTweet]` singleton instance.

**Share a full-text status:**

```
- (void)shareTextStatus:(NSString *)status
         withCompletion:(HLInstaTweetPostCompletion)completion
            andDelegate:(id<HLInstaTweetDelegate>)delegate;
```

**Share a photo and a status:**

```
- (void)sharePhoto:(UIImage *)photo withTextStatus:(NSString *)status
     withCompletion:(HLInstaTweetPostCompletion)completion
       andDelegate:(id<HLInstaTweetDelegate>)delegate;
```

Completion is always called **on the main thread**.

### HLInstaTweetDelegate

You **must**  implement `instaTweetClientWillDisplayAccountSelectorInView:` delegate method to tell in which view the account picker should be presented if needed.

You can catch **errors or exceptions** using optional methods.

-	`switchedToAccountWithUsername:` when a new default account is registered
-	`instaTweetClientUnauthorized:` if the user forbids access to his Twitter accounts
-	`instaTweetClientNoAccountConfigured:` is no Twitter account is set up on the device
-	`instaTweetClientDidCancelAccountPicking:` if the user did cancel account picking
-	`instaTweetClientUnknownError:` if an unknown error is raised

### Helpers

-	`activeSessionUsername:` returns the current Twitter account username
-	`switchActiveSessionAccount:` to switch default Twitter account

## Credits

HLInstaTweet was developed by [Hervé Heurtault de Lammerville](http://www.hervedroit.com). If you have any feature suggestion or bug report, please help out by creating [an issue](https://github.com/fiftydegrees/HLInstaTweet/issues/new) on GitHub. If you're using HLInstaTweet in your project, please let me know.