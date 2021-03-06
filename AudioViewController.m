//
//  AudioViewController.m
//  ChineseWheel
//
//  Created by GraceXu on 15/04/15.
//
//


#import "AudioViewController.h"
#import "ISESettingViewController.h"
#import "PopupView.h"
#import "ISEParams.h"
#import "IFlyMSC/IFlyMSC.h"

#import "ISEResult.h"
#import "ISEResultXmlParser.h"
#import "ViewUIPrefix.h"

extern NSString * zodiacName;

#pragma mark - const values

NSString* const KCIseViewControllerTitle=@"语音评测";
NSString* const KCIseHideBtnTitle=@"隐藏";
NSString* const KCIseSettingBtnTitle=@"设置";
NSString* const KCIseStartBtnTitle=@"开始评测";
NSString* const KCIseStopBtnTitle=@"停止评测";
NSString* const KCIseParseBtnTitle=@"结果解析";
NSString* const KCIseCancelBtnTitle=@"取消评测";

NSString* const KCTextCNWord=@"text_cn_word";
NSString* const KCTextCNSentence=@"text_cn_sentence";
NSString* const KCTextENWord=@"text_en_word";
NSString* const KCTextENSentence=@"text_en_sentence";

NSString* const KCResultNotify1=@"请点击“开始评测”按钮";
NSString* const KCResultNotify2=@"请朗读以上内容";
NSString* const KCResultNotify3=@"停止评测，结果等待中...";


#pragma mark -

@interface AudioViewController () <IFlySpeechEvaluatorDelegate ,ISESettingDelegate ,ISEResultXmlParserDelegate>
@property (strong, nonatomic) IBOutlet UIButton *backBtn;

@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, assign) CGFloat textViewHeight;
@property (nonatomic, strong) UITextView *resultView;
@property (nonatomic, strong) NSString* resultText;
@property (nonatomic, assign) CGFloat resultViewHeight;
@property (strong, nonatomic) IBOutlet UIImageView *soundView;

@property (nonatomic, strong) UIButton *startBtn;
@property (nonatomic, strong) UIButton *stopBtn;
@property (nonatomic, strong) UIButton *parseBtn;
@property (nonatomic, strong) UIButton *cancelBtn;

@property (nonatomic, strong) PopupView *popupView;
@property (nonatomic, strong) ISESettingViewController *settingViewCtrl;
@property (nonatomic, strong) IFlySpeechEvaluator *iFlySpeechEvaluator;

@property (nonatomic, assign) BOOL isSessionResultAppear;
@property (nonatomic, assign) BOOL isSessionEnd;

@property (nonatomic, assign) BOOL isValidInput;

@property (nonatomic, strong) NSString * result;
@property (strong, nonatomic) IBOutlet UIButton *recordBtn;

@property (strong, nonatomic) IBOutlet UIImageView *backgroundView;
@property (retain, nonatomic) AVAudioPlayer *avPlay;
@property(strong, nonatomic) NSURL* myurl;
@property(strong, nonatomic) NSString* KCTextCNSyllable;



@end




@implementation AudioViewController
//control

- (IBAction)reviewBtnDown:(id)sender {
        UIStoryboard *secondStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        [self presentModalViewController:[secondStoryboard instantiateViewControllerWithIdentifier:@"ScratchView"] animated:YES ];
}
- (IBAction)backBtnDown:(id)sender {
    UIStoryboard *secondStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    [self presentModalViewController:[secondStoryboard instantiateViewControllerWithIdentifier:@"WheelView"] animated:YES ];
}

static NSString *LocalizedEvaString(NSString *key, NSString *comment) {
    return NSLocalizedStringFromTable(key, @"eva/eva", comment);

}


- (IBAction)playSound:(id)sender {
    if (self.avPlay.playing) {
        [self.avPlay stop];
        return;
    }
    AVAudioPlayer *player = [[AVAudioPlayer alloc]initWithContentsOfURL:self.myurl error:nil];
    self.avPlay = player;
    [self.avPlay play];
}

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    _iFlySpeechEvaluator = [IFlySpeechEvaluator sharedInstance];
    _iFlySpeechEvaluator.delegate = self;
    
    //清空参数
    [_iFlySpeechEvaluator setParameter:@"" forKey:[IFlySpeechConstant PARAMS]];
    
    _isSessionResultAppear=YES;
    _isSessionEnd=YES;
    _isValidInput=YES;
    
    
    return self;
}



- (void)viewWillAppear:(BOOL)animated {
    
    // register for keyboard notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated{
    
    
    // unregister for keyboard notifications while not visible.
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
    
    [self.iFlySpeechEvaluator cancel];
    self.resultView.text =KCResultNotify1;
    self.resultText=@"";
    
    [super viewWillDisappear:animated];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    //语音
    NSBundle* bundle=[NSBundle mainBundle];
    NSString* urlString=[bundle pathForResource:zodiacName ofType:@"mp3"];
    //--初始化url
    self.myurl=[[NSURL alloc]initFileURLWithPath:urlString];
    //--初始化 语音的字
    if([zodiacName isEqualToString:@"1"]){
        self.KCTextCNSyllable = @"鼠";
    }else if([zodiacName isEqualToString:@"2"]){
        self.KCTextCNSyllable = @"牛";
    }else if([zodiacName isEqualToString:@"3"]){
        self.KCTextCNSyllable = @"虎";
    }else if([zodiacName isEqualToString:@"4"]){
        self.KCTextCNSyllable = @"兔";
    }else if([zodiacName isEqualToString:@"5"]){
        self.KCTextCNSyllable = @"龙";
    }else if([zodiacName isEqualToString:@"6"]){
        self.KCTextCNSyllable = @"蛇";
    }else if([zodiacName isEqualToString:@"7"]){
        self.KCTextCNSyllable = @"马";
    }else if([zodiacName isEqualToString:@"8"]){
        self.KCTextCNSyllable = @"羊";
    }else if([zodiacName isEqualToString:@"9"]){
        self.KCTextCNSyllable = @"猴";
    }else if([zodiacName isEqualToString:@"10"]){
        self.KCTextCNSyllable = @"鸡";
    }else if([zodiacName isEqualToString:@"11"]){
        self.KCTextCNSyllable = @"狗";
    }else if([zodiacName isEqualToString:@"12"]){
        self.KCTextCNSyllable = @"猪";
    }
    
    NSString * backName = [zodiacName stringByAppendingString:@"_background.png"];
    [self.backgroundView  setImage:[UIImage imageNamed:backName]];
    int textViewHeight = self.view.frame.size.height - _DEMO_UI_BUTTON_HEIGHT * 2 - _DEMO_UI_MARGIN * 10 - _DEMO_UI_NAVIGATIONBAR_HEIGHT;
    
    //textView
    UITextView *textView = [[UITextView alloc] initWithFrame:
                            CGRectMake(_DEMO_UI_MARGIN * 2,
                                       _DEMO_UI_MARGIN * 2,
                                       self.view.frame.size.width - _DEMO_UI_MARGIN * 4,
                                       textViewHeight / 2)];
    
    textView.layer.cornerRadius = 8;
    textView.layer.borderWidth = 1;
    textView.text = @"";
    textView.font = [UIFont systemFontOfSize:17.0f];
    textView.pagingEnabled = YES;
    
    UIEdgeInsets edgeInsets = [textView contentInset];
    edgeInsets.left = 10;
    edgeInsets.right = 10;
    edgeInsets.top = 10;
    edgeInsets.bottom = 10;
    textView.contentInset = edgeInsets;
    [textView setEditable:YES];
    self.textView = textView;
    self.textViewHeight=self.textView.frame.size.height;
    //        [self.view addSubview:textView];
    
    //resultView
    UITextView *resultView = [[UITextView alloc] initWithFrame:
                              CGRectMake(_DEMO_UI_MARGIN * 2,
                                         textView.frame.size.height + _DEMO_UI_MARGIN * 3,
                                         self.view.frame.size.width - _DEMO_UI_MARGIN * 4,
                                         textViewHeight / 2)];
    resultView.layer.cornerRadius = 8;
    resultView.layer.borderWidth = 1;
    resultView.text = @"";
    resultView.font = [UIFont systemFontOfSize:17.0f];
    resultView.pagingEnabled = YES;
    
    resultView.contentInset = edgeInsets;
    [resultView setEditable:NO];
    self.resultView = resultView;
    self.resultView.text =KCResultNotify1;
    self.resultViewHeight=self.resultView.frame.size.height;
    //        [self.view addSubview:resultView];
    
    
    
    //开始
    UIButton *startBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [startBtn setTitle:KCIseStartBtnTitle forState:UIControlStateNormal];
    startBtn.frame = CGRectMake(_DEMO_UI_MARGIN * 2,
                                resultView.frame.origin.y + resultView.frame.size.height + _DEMO_UI_MARGIN,
                                (self.view.frame.size.width - _DEMO_UI_PADDING * 3) / 2,
                                _DEMO_UI_BUTTON_HEIGHT);
    
    [startBtn addTarget:self action:@selector(onBtnStart:) forControlEvents:UIControlEventTouchUpInside];
    
    
    self.startBtn = startBtn;
//    [self.view addSubview:startBtn];
    
    
    [self.recordBtn addTarget:self action:@selector(onBtnStart:) forControlEvents:UIControlEventTouchDown];
    [self.recordBtn addTarget:self action:@selector(onBtnStop:) forControlEvents:UIControlEventTouchUpInside];
    
    
    UIButton *parseBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [parseBtn setTitle:KCIseParseBtnTitle forState:UIControlStateNormal];
    parseBtn.frame = CGRectMake(startBtn.frame.origin.x + _DEMO_UI_PADDING + startBtn.frame.size.width,
                                resultView.frame.origin.y + resultView.frame.size.height + _DEMO_UI_MARGIN,
                                startBtn.frame.size.width,
                                startBtn.frame.size.height);
    
    [parseBtn addTarget:self action:@selector(onBtnParse:) forControlEvents:UIControlEventTouchUpInside];
    self.parseBtn = parseBtn;
//    [self.view addSubview:parseBtn];
    
    //停止
    UIButton *stopBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [stopBtn setTitle:KCIseStopBtnTitle forState:UIControlStateNormal];
    stopBtn.frame = CGRectMake(_DEMO_UI_PADDING,
                               startBtn.frame.origin.y + startBtn.frame.size.height + _DEMO_UI_MARGIN,
                               (self.view.frame.size.width - _DEMO_UI_PADDING * 3) / 2,
                               _DEMO_UI_BUTTON_HEIGHT);
    [stopBtn addTarget:self action:@selector(onBtnStop:) forControlEvents:UIControlEventTouchUpInside];
    self.stopBtn = stopBtn;
//    [self.view addSubview:stopBtn];
    
    
    //取消
    UIButton *cancelBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [cancelBtn setTitle:KCIseCancelBtnTitle forState:UIControlStateNormal];
    cancelBtn.frame = CGRectMake(stopBtn.frame.origin.x + _DEMO_UI_PADDING + stopBtn.frame.size.width,
                                 stopBtn.frame.origin.y,
                                 stopBtn.frame.size.width,
                                 stopBtn.frame.size.height);
    [cancelBtn addTarget:self action:@selector(onBtnCancel:) forControlEvents:UIControlEventTouchUpInside];
    self.cancelBtn = cancelBtn;
//    [self.view addSubview:cancelBtn];
    
    //popupView
    self.popupView = [[PopupView alloc]initWithFrame:CGRectMake(100, 300, 0, 0)];
    self.popupView.ParentView = self.view;
    
    //SettingView
    UIBarButtonItem *settingBtn = [[UIBarButtonItem alloc] initWithTitle:KCIseSettingBtnTitle
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(onSetting:)];
    
    
    
    
    if (!self.iFlySpeechEvaluator) {
        self.iFlySpeechEvaluator = [IFlySpeechEvaluator sharedInstance];
    }
    self.iFlySpeechEvaluator.delegate = self;
    //清空参数，目的是评测和听写的参数采用相同数据
    [self.iFlySpeechEvaluator setParameter:@"" forKey:[IFlySpeechConstant PARAMS]];
    self.iseParams=[ISEParams fromUserDefaults];
    [self reloadCategoryText];
}

-(void)reloadCategoryText{
    
    [self.iFlySpeechEvaluator setParameter:self.iseParams.bos forKey:[IFlySpeechConstant VAD_BOS]];
    [self.iFlySpeechEvaluator setParameter:self.iseParams.eos forKey:[IFlySpeechConstant VAD_EOS]];
    [self.iFlySpeechEvaluator setParameter:self.iseParams.category forKey:[IFlySpeechConstant ISE_CATEGORY]];
    [self.iFlySpeechEvaluator setParameter:self.iseParams.language forKey:[IFlySpeechConstant LANGUAGE]];
    [self.iFlySpeechEvaluator setParameter:self.iseParams.rstLevel forKey:[IFlySpeechConstant ISE_RESULT_LEVEL]];
    [self.iFlySpeechEvaluator setParameter:self.iseParams.timeout forKey:[IFlySpeechConstant SPEECH_TIMEOUT]];
    
    if ([self.iseParams.language isEqualToString:KCLanguageZHCN]) {
        if ([self.iseParams.category isEqualToString:KCCategorySyllable]) {
            self.textView.text = LocalizedEvaString(self.KCTextCNSyllable, nil);
        }
        else if ([self.iseParams.category isEqualToString:KCCategoryWord]) {
            self.textView.text = LocalizedEvaString(KCTextCNWord, nil);
        }
        else {
            self.textView.text = LocalizedEvaString(KCTextCNSentence, nil);
        }
    }
    else {
        if ([self.iseParams.category isEqualToString:KCCategoryWord]) {
            self.textView.text = LocalizedEvaString(KCTextENWord, nil);
        }
        else {
            self.textView.text = LocalizedEvaString(KCTextENSentence, nil);
        }
        self.isValidInput=YES;
        
    }
}
- (IBAction)recordBtnDown:(id)sender {
    
}

-(void)resetBtnSatus:(IFlySpeechError *)errorCode{
    
    if(errorCode && errorCode.errorCode!=0){
        self.isSessionResultAppear=NO;
        self.isSessionEnd=YES;
        self.resultView.text =KCResultNotify1;
        self.resultText=@"";
    }else{
        self.isSessionResultAppear=YES;
        self.isSessionEnd=YES;
    }
    self.startBtn.enabled=YES;
}

#pragma mark - keyboard

/*!
 *  隐藏键盘
 *
 *  @param sender textView or resultView
 */
-(void)onKeyBoardDown:(id) sender{
    [self.textView resignFirstResponder];
}




#pragma mark -
#pragma mark - Button handler


/*!
 *  开始录音
 *
 *  @param sender startBtn
 */
- (void)onBtnStart:(id)sender {
    
    [self.iFlySpeechEvaluator setParameter:@"16000" forKey:[IFlySpeechConstant SAMPLE_RATE]];
    [self.iFlySpeechEvaluator setParameter:@"utf-8" forKey:[IFlySpeechConstant TEXT_ENCODING]];
    [self.iFlySpeechEvaluator setParameter:@"xml" forKey:[IFlySpeechConstant ISE_RESULT_TYPE]];
    
    
    
    NSStringEncoding encoding = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
    
    NSLog(@"text encoding:%@",[self.iFlySpeechEvaluator parameterForKey:[IFlySpeechConstant TEXT_ENCODING]]);
    NSLog(@"language:%@",[self.iFlySpeechEvaluator parameterForKey:[IFlySpeechConstant LANGUAGE]]);
    
    BOOL isUTF8=[[self.iFlySpeechEvaluator parameterForKey:[IFlySpeechConstant TEXT_ENCODING]] isEqualToString:@"utf-8"];
    BOOL isZhCN=[[self.iFlySpeechEvaluator parameterForKey:[IFlySpeechConstant LANGUAGE]] isEqualToString:KCLanguageZHCN];
    
    BOOL needAddTextBom=isUTF8&&isZhCN;
    NSMutableData *buffer = nil;
    if(needAddTextBom){
        if(self.textView.text && [self.textView.text length]>0){
            Byte bomHeader[] = { 0xEF, 0xBB, 0xBF };
            buffer = [NSMutableData dataWithBytes:bomHeader length:sizeof(bomHeader)];
            [buffer appendData:[self.textView.text dataUsingEncoding:NSUTF8StringEncoding]];
            NSLog(@" \ncn buffer length: %lu",(unsigned long)[buffer length]);
        }
    }else{
        buffer= [NSMutableData dataWithData:[self.textView.text dataUsingEncoding:encoding]];
        NSLog(@" \nen buffer length: %lu",(unsigned long)[buffer length]);
    }
    self.resultView.text =KCResultNotify2;
    self.resultText=@"";
    [self.iFlySpeechEvaluator startListening:buffer params:nil];
    self.isSessionResultAppear=NO;
    self.isSessionEnd=NO;
    self.startBtn.enabled=NO;
    
    
    
}



/*!
 *  暂停录音
 *
 *  @param sender stopBtn
 */
- (void)onBtnStop:(id)sender {
    
    if(!self.isSessionResultAppear &&  !self.isSessionEnd){
        self.resultView.text =KCResultNotify3;
        self.resultText=@"";
    }
    
    [self.iFlySpeechEvaluator stopListening];
    [self.resultView resignFirstResponder];
    [self.textView resignFirstResponder];
    self.startBtn.enabled=YES;
    [self.recordBtn setBackgroundImage:[UIImage imageNamed:@"record_animate_00.png"] forState:UIControlStateNormal];
     [self.soundView setImage:nil];
    
    
    
}

/*!
 *  取消
 *
 *  @param sender cancelBtn
 */
- (void)onBtnCancel:(id)sender {
    
    [self.iFlySpeechEvaluator cancel];
    [self.resultView resignFirstResponder];
    [self.textView resignFirstResponder];
    [self.popupView removeFromSuperview];
    self.resultView.text =KCResultNotify1;
    self.resultText=@"";
    self.startBtn.enabled=YES;
}


/*!
 *  开始解析
 *
 *  @param sender parseBtn
 */
- (void)onBtnParse:(id)sender {
    
    ISEResultXmlParser* parser=[[ISEResultXmlParser alloc] init];
    parser.delegate = self;
    [parser parserXml:self.resultText];
    
}


#pragma mark - ISESettingDelegate

/*!
 *  设置参数改变
 *
 *  @param params 参数
 */
- (void)onParamsChanged:(ISEParams *)params {
    self.iseParams=params;
    [self performSelectorOnMainThread:@selector(reloadCategoryText) withObject:nil waitUntilDone:NO];
}

#pragma mark - IFlySpeechEvaluatorDelegate
/*!
 *  音量和数据回调
 *
 *  @param volume 音量
 *  @param buffer 音频数据
 */
- (void)onVolumeChanged:(int)volume buffer:(NSData *)buffer {
    //    NSLog(@"volume:%d",volume);
    [self.popupView setText:[NSString stringWithFormat:@"Current Volume：%d",volume]];
    [self.view addSubview:self.popupView];
    //    double volume2 = (double) volume;
    
    if (0 < volume && volume<= 3) {
        [self.recordBtn setBackgroundImage:[UIImage imageNamed:@"record_animate_01.png"] forState:UIControlStateNormal];
        [self.soundView setImage:[UIImage imageNamed:@"record_animate_01.png"]];
    }
    else  if (3<volume && volume <=6) {
        [self.recordBtn setBackgroundImage:[UIImage imageNamed:@"record_animate_02.png"] forState:UIControlStateNormal];
        [self.soundView setImage:[UIImage imageNamed:@"record_animate_02.png"]];
    }
    else  if (6<volume && volume <=9) {
        [self.recordBtn setBackgroundImage:[UIImage imageNamed:@"record_animate_03.png"] forState:UIControlStateNormal];
        [self.soundView setImage:[UIImage imageNamed:@"record_animate_03.png"]];
    }
    else  if (9 <volume && volume <=12) {
        [self.recordBtn setBackgroundImage:[UIImage imageNamed:@"record_animate_04.png"] forState:UIControlStateNormal];
        [self.soundView setImage:[UIImage imageNamed:@"record_animate_04.png"]];
    }
    else  if (12<volume && volume <=15) {
        [self.recordBtn setBackgroundImage:[UIImage imageNamed:@"record_animate_05.png"] forState:UIControlStateNormal];
        [self.soundView setImage:[UIImage imageNamed:@"record_animate_05.png"]];
    }
    else  if (15<volume && volume<=18) {
        [self.recordBtn setBackgroundImage:[UIImage imageNamed:@"record_animate_06.png"] forState:UIControlStateNormal];
        [self.soundView setImage:[UIImage imageNamed:@"record_animate_06.png"]];
    }
    else  if (18<volume && volume<=21) {
        [self.recordBtn setBackgroundImage:[UIImage imageNamed:@"record_animate_07.png"] forState:UIControlStateNormal];
        [self.soundView setImage:[UIImage imageNamed:@"record_animate_07.png"]];
    }
    else  if (21<volume && volume<=24) {
        [self.recordBtn setBackgroundImage:[UIImage imageNamed:@"record_animate_08.png"] forState:UIControlStateNormal];
        [self.soundView setImage:[UIImage imageNamed:@"record_animate_08.png"]];
    }
    else  if (24<volume && volume<=30) {
        [self.recordBtn setBackgroundImage:[UIImage imageNamed:@"record_animate_09.png"] forState:UIControlStateNormal];
        [self.soundView setImage:[UIImage imageNamed:@"record_animate_09.png"]];
    }
    else   {
        [self.recordBtn setBackgroundImage:[UIImage imageNamed:@"record_animate_00.png"] forState:UIControlStateNormal];
        [self.soundView setImage:nil];
    }
    
}



/*!
 *  开始录音回调
 *  当调用了`startListening`函数之后，如果没有发生错误则会回调此函数。如果发生错误则回调onError:函数
 */
- (void)onBeginOfSpeech {
    
}

/*!
 *  停止录音回调
 *    当调用了`stopListening`函数或者引擎内部自动检测到断点，如果没有发生错误则回调此函数。
 *  如果发生错误则回调onError:函数
 */
- (void)onEndOfSpeech {
    
}

/*!
 *  正在取消
 */
- (void)onCancel {
    
}

/*!
 *  评测结果回调
 *    在进行语音评测过程中的任何时刻都有可能回调此函数，你可以根据errorCode进行相应的处理.
 *  当errorCode没有错误时，表示此次会话正常结束，否则，表示此次会话有错误发生。特别的当调用
 *  `cancel`函数时，引擎不会自动结束，需要等到回调此函数，才表示此次会话结束。在没有回调此函
 *  数之前如果重新调用了`startListenging`函数则会报错误。
 *
 *  @param errorCode 错误描述类
 */
- (void)onError:(IFlySpeechError *)errorCode {
    if(errorCode && errorCode.errorCode!=0){
        [self.popupView setText:[NSString stringWithFormat:@"Error code：%d %@",[errorCode errorCode],[errorCode errorDesc]]];
        [self.view addSubview:self.popupView];
        
    }
    
    [self performSelectorOnMainThread:@selector(resetBtnSatus:) withObject:errorCode waitUntilDone:NO];
    
}

/*!
 *  评测结果回调
 *   在评测过程中可能会多次回调此函数，你最好不要在此回调函数中进行界面的更改等操作，只需要将回调的结果保存起来。
 *
 *  @param results -[out] 评测结果。
 *  @param isLast  -[out] 是否最后一条结果
 */
- (void)onResults:(NSData *)results isLast:(BOOL)isLast{
    if (results) {
        NSString *showText = @"";
        
        const char* chResult=[results bytes];
        
        BOOL isUTF8=[[self.iFlySpeechEvaluator parameterForKey:[IFlySpeechConstant RESULT_ENCODING]]isEqualToString:@"utf-8"];
        NSString* strResults=nil;
        if(isUTF8){
            strResults=[[NSString alloc] initWithBytes:chResult length:[results length] encoding:NSUTF8StringEncoding];
        }else{
            NSLog(@"result encoding: gb2312");
            NSStringEncoding encoding = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
            strResults=[[NSString alloc] initWithBytes:chResult length:[results length] encoding:encoding];
        }
        if(strResults){
            showText = [showText stringByAppendingString:strResults];
        }
        self.result = [NSString stringWithString:showText];
        
        NSLog(self.result);
        
        self.resultText=showText;
        self.resultView.text = showText;
        self.isSessionResultAppear=YES;
        self.isSessionEnd=YES;
 
        if(isLast){
            [self.popupView setText:@"评测结束"];
            [self.view addSubview:self.popupView];
        }
        
        ISEResultXmlParser* parser=[[ISEResultXmlParser alloc] init];
        parser.delegate = self;
        [parser parserXml:self.resultText];
        
        
    }
    else{
        if(isLast){
            [self.popupView setText:@"你好像没有说话哦"];
            [self.view addSubview:self.popupView];
        }
        self.isSessionEnd=YES;
    }
    self.startBtn.enabled=YES;
}

#pragma mark - ISEResultXmlParserDelegate

-(void)onISEResultXmlParser:(NSXMLParser *)parser Error:(NSError*)error{
    
}

-(void)onISEResultXmlParserResult:(ISEResult*)result{
    self.resultView.text=[result toString];
//    NSLog([result toString]);
    NSLog(@"%f",[result total_score]);
    double score = [result total_score];
    score = score * 20;
    NSLog(@"%@",[result content]);
    double time = [result time_len];
    
    NSString * title ;
    NSString * message;
    NSString * confirm = @"OK";
    
    if (score < 50) {
        title = @"Something Wrong??";
        message = @"try again?";

    }else if(score < 80){
        title  = @"You could be better~~, try again";
        message = [NSString stringWithFormat: @"You got a score ：%.2f ", score];
        [self.view addSubview:self.popupView];
        
    }else{
        self.backBtn.enabled = true;
        title = @"Congratulations";
        message = [NSString stringWithFormat: @"You got a score ：%.2f ", score];
        
    
    }
    
    UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:title
                                                       message:message
                                                      delegate:nil
                                             cancelButtonTitle:confirm
                                             otherButtonTitles:nil];
    [alertView show];

}


@end
