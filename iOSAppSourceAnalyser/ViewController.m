//
//  ViewController.m
//  iOSAppSourceAnalyser
//
//  Created by 이승환 on 2014. 11. 5..
//  Copyright (c) 2014년 SK Communications. All rights reserved.
//

#import "ViewController.h"




@interface ViewController ()

@property (nonatomic, weak) IBOutlet    NSTextField             *rootPathTextField;
@property (nonatomic, weak) IBOutlet    NSTextField             *projectFilePathTextField;

@property (nonatomic, strong)           NSString                *projectFileContents;

@end




@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Do any additional setup after loading the view.
}


- (void)setRepresentedObject:(id)representedObject
{
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}


- (NSArray*)noProcessDirectoryNameList
{
    return @[@".svn"];
}


- (IBAction)tapGoBtn:(id)sender
{
    NSString *rootPath = [_rootPathTextField stringValue];
    NSString *prjtFilePath = [_projectFilePathTextField stringValue];
    
    
    NSLog(@"root path : %@", rootPath);
    NSLog(@"prjt path : %@", prjtFilePath);
    

    NSFileManager *fileMgr = [NSFileManager defaultManager];
    NSError *error = nil;
    
    
    _projectFileContents = [NSString stringWithContentsOfFile:prjtFilePath encoding:NSUTF8StringEncoding error:&error];
    if (nil == _projectFileContents)
    {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:[NSString stringWithFormat:@"project file does not be opened.\n%@", [error localizedDescription]]];
        [alert runModal];
        return ;
    }
    
    
    NSDictionary *fileAttribute = [fileMgr attributesOfItemAtPath:rootPath error:&error];
    NSString* fileType = fileAttribute[NSFileType];
    if ([fileType isEqualToString:NSFileTypeDirectory])
    {
        [self processDirectoryContents:rootPath];
    }
    else
    {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"Root Path Should be directory path!"];
        [alert runModal];
    }
}


- (void)processDirectoryContents:(NSString*)directoryPath
{
    __block BOOL noProcess = NO;

    [[self noProcessDirectoryNameList] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([[directoryPath lastPathComponent] isEqualToString:obj])
        {
            *stop = YES;
            noProcess = YES;
        }
    }];
    
    if (noProcess) {
        return ;
    }
    
    
    
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    __block NSError *error = nil;

    
    NSArray *contents = [fileMgr contentsOfDirectoryAtPath:directoryPath error:&error];
    [contents enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        NSString *path = [directoryPath stringByAppendingPathComponent:obj];
        
        NSDictionary *fileAttribute = [fileMgr attributesOfItemAtPath:path error:&error];
        if (fileAttribute == nil)
        {
            *stop = YES;
            
            NSAlert *alert = [NSAlert alertWithError:error];
            [alert runModal];
            return ;
        }

        
        NSString* fileType = fileAttribute[NSFileType];
        if ([fileType isEqualToString:NSFileTypeDirectory])
        {
            [self processDirectoryContents:path];
        }
        else if ([fileType isEqualToString:NSFileTypeRegular])
        {
            [self processFile:path];
        }
    }];
    
}


- (void)processFile:(NSString*)filePath
{
    NSError *error = nil;
    
    
    NSArray *pathComponents = [filePath pathComponents];
    NSString *pathExtension = [filePath pathExtension];
    NSString *fileName      = [filePath lastPathComponent];
    NSString *fileNameOnly  = [self fileNameOnly:fileName];
    
    
//    // 1. project 파일이면, project 내용 보관.
//    if ([pathExtension isEqualToString:@"pbxproj"])
//    {
//        NSString *projectName = [self fileNameOnly:pathComponents[[pathComponents count]-2]];
//        
//        _projectFileContentsDic[projectName] = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
//        
//        
////        NSLog(@"%@", _projectFileContentsDic[pathComponents[[pathComponents count]-2]]);
//        
//        return ;
//    }
    

    // 2. header file이 아니면 처리 X.
    if (![pathExtension isEqualToString:@"h"])
    {
        return ;
    }
    

    // 3. header file이 project에 사용되는 것인지 확인.
//    __block BOOL used = NO;
//    [[_projectFileContentsDic allKeys] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
//        
//        NSString *dicKey = obj;
//        
//        __block BOOL found = NO;
//        [pathComponents enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
//            
//            if ([dicKey isEqualToString:obj])
//            {
//                found = YES;
//                *stop = YES;
//            }
//            
//        }];
//        
//        if (found)
//        {
//            NSRange range = [_projectFileContentsDic[dicKey] rangeOfString:fileName];
//            if (range.location != NSNotFound)
//            {
//                used = YES;
//            }
//            
//            *stop = YES;
//        }
//        
//    }];
//    
//    if (!used)
//    {
//        return ;
//    }
    NSRange range = [_projectFileContents rangeOfString:fileName];
    if (range.location == NSNotFound)
    {
        return ;
    }
    
    
//    NSLog(@"file : %@", filePath);
    
    
    NSString *headerFileContent = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
    NSArray *fileComponents = [headerFileContent componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\r\n\t "]];
    [fileComponents enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isEqualToString:@"@interface"])
        {
            NSLog(@"%@ in %@", fileComponents[idx+1], fileName);
        }
    }];
}


- (NSString*)fileNameOnly:(NSString*)fileName
{
    NSString *pathExtension = [NSString stringWithFormat:@".%@", [fileName pathExtension]];
    NSString *fileNameOnly  = fileName;
    
    
    if ([pathExtension length])
    {
        NSRange range = [fileName rangeOfString:pathExtension];
        if (range.location != NSNotFound)
        {
            fileNameOnly = [fileName substringToIndex:range.location];
        }
    }
    
    return fileNameOnly;
}


@end
