//
//  ViewController.m
//  BlocBrowser
//
//  Created by Jonathan Jungemann on 10/5/14.
//  Copyright (c) 2014 Jon Jungemann. All rights reserved.
//

#import "WebBrowserViewController.h"
#import "AwesomeFloatingToolbar.h"

#define WebBrowserBackString NSLocalizedString(@"Back", @"Back command")
#define WebBrowserForwardString NSLocalizedString(@"Forward", @"Forward command")
#define WebBrowserStopString NSLocalizedString(@"Stop", @"Stop command")
#define WebBrowserRefreshString NSLocalizedString(@"Refresh", @"Reload command")

@interface WebBrowserViewController () <UIWebViewDelegate, UITextFieldDelegate, AwesomeFloatingToolbarDelegate>

@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) AwesomeFloatingToolbar *awesomeToolbar;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;


@property (nonatomic, assign) NSUInteger frameCount;

@end

@implementation WebBrowserViewController

#pragma mark - UIViewController

- (void)loadView {
    UIView *mainView = [UIView new];
    
    self.webView = [[UIWebView alloc] init];
    self.webView.delegate = self;
    
    self.textField = [[UITextField alloc] init];
    self.textField.keyboardType = UIKeyboardTypeURL;
    self.textField.returnKeyType = UIReturnKeyDone;
    self.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.textField.placeholder = NSLocalizedString(@"Type Website or Search", @"Placeholder text for web browser URL field");
    self.textField.backgroundColor = [UIColor colorWithWhite:220/255.0f alpha:1];
    self.textField.delegate = self;
    
    
    self.awesomeToolbar = [[AwesomeFloatingToolbar alloc] initWithFourTitles:@[WebBrowserBackString, WebBrowserForwardString, WebBrowserStopString, WebBrowserRefreshString]];

    self.awesomeToolbar.delegate = self;

    for (UIView *viewToAdd in @[self.webView, self.textField, self.awesomeToolbar]) {
        [mainView addSubview:viewToAdd];
    }
    
    self.view = mainView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.activityIndicator];
}

- (void) viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    //First, calculate some dimensions.
    static CGFloat itemHeight = 50;
    CGFloat width = CGRectGetWidth(self.view.bounds);
    CGFloat browserHeight = CGRectGetHeight(self.view.bounds) - itemHeight;

    //Now, assign the frames
    self.textField.frame = CGRectMake(0, 0, width, itemHeight);
    self.webView.frame = CGRectMake(0, CGRectGetMaxY(self.textField.frame), width, browserHeight);
    
    self.awesomeToolbar.frame = CGRectMake(20, 70, 280, 60);
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    NSString *URLString = textField.text;
    NSString *searchQuery;
    
    NSURL *URL = [NSURL URLWithString:URLString];
    
    NSRange whiteSpace = [URLString rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if (whiteSpace.location != NSNotFound) {
        
        searchQuery = [URLString stringByReplacingOccurrencesOfString:@" " withString:@"+"];
        URL = [NSURL URLWithString:[NSString stringWithFormat:@"https://www.google.com/search?q=%@", searchQuery]];
   
    }
    
    if (!URL.scheme) {
        // The user didn't type http: or https:
        URL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@", URLString]];
    }
    
    if (URL) {
        NSURLRequest *request = [NSURLRequest requestWithURL:URL];
        [self.webView loadRequest:request];
    }
    
    return NO;
}

#pragma mark - UIWebViewDelegate

- (void)webViewDidStartLoad:(UIWebView *)webView {
    self.frameCount++;
    [self updateButtonsAndTitle];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    self.frameCount--;
    [self updateButtonsAndTitle];
}

- (void) resetWebView {
    [self.webView removeFromSuperview];
    
    UIWebView *newWebView = [[UIWebView alloc] init];
    newWebView.delegate = self;
    [self.view addSubview:newWebView];
    
    self.webView = newWebView;
    
    self.textField.text = nil;
    [self updateButtonsAndTitle];
    
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    if (error.code != -999) {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"Error")
                                                    message:[error localizedDescription]
                                                   delegate:nil
                                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                          otherButtonTitles:nil];
    [alert show];
    }
    
    [self updateButtonsAndTitle];
    self.frameCount--;
}

#pragma mark - Miscellaneous

- (void) updateButtonsAndTitle {
    NSString *webpageTitle = [self.webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    
    if (webpageTitle) {
        self.title = webpageTitle;
    } else {
        self.title = self.webView.request.URL.absoluteString;
    }
    
    if (self.frameCount > 0) {
        [self.activityIndicator startAnimating];
    } else {
        [self.activityIndicator stopAnimating];
    }
    
    [self.awesomeToolbar setEnabled:[self.webView canGoBack] forButtonWithTitle:WebBrowserBackString];
    [self.awesomeToolbar setEnabled:[self.webView canGoForward] forButtonWithTitle:WebBrowserForwardString];
    [self.awesomeToolbar setEnabled:self.frameCount > 0 forButtonWithTitle:WebBrowserStopString];
    [self.awesomeToolbar setEnabled:self.webView.request.URL && self.frameCount == 0 forButtonWithTitle:WebBrowserRefreshString];
    
}

#pragma mark - BLCAwesomeFloatingToolbarDelegate

- (void) floatingToolbar:(AwesomeFloatingToolbar *)toolbar didSelectButtonWithTitle:(NSString *)title {
    if ([title isEqual:WebBrowserBackString]) {
        [self.webView goBack];
    } else if ([title isEqual:WebBrowserForwardString]) {
        [self.webView goForward];
    } else if ([title isEqual:WebBrowserStopString]) {
        [self.webView stopLoading];
    } else if ([title isEqual:WebBrowserRefreshString]) {
        [self.webView reload];
    }
}

@end
