//
//  ZHHttpManager+Cache.m
//  test
//
//  Created by AdminZhiHua on 15/12/8.
//  Copyright © 2015年 AdminZhiHua. All rights reserved.
//

#import "ZHHttpManager+Cache.h"
#import <FMDB.h>

static FMDatabase *_db;

@implementation ZHHttpManager (Cache)

+ (void)initialize {
    
    NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    
    NSString *dbPath = [documentPath stringByAppendingPathComponent:@"HTTP.sqlite"];
    
    _db = [FMDatabase databaseWithPath:dbPath];
    
    if ([_db open])
    {
        NSLog(@"打开成功");
        
        BOOL success = [_db executeUpdate:@"create table if not exists http_cache (id integer primary key autoincrement,url text,params blob,responseObject blob not null);"];
        
        if (success) NSLog(@"创表成功");
        
        else NSLog(@"创表失败");
        
    }
    else
    {
        NSLog(@"打开失败");
    }
    
}

+ (void)saveDataWith:(NSString *)path parameters:(NSDictionary *)params responseObject:(id)object {
    
    NSData *paramsData = [NSJSONSerialization dataWithJSONObject:params options:NSJSONWritingPrettyPrinted error:NULL];
    NSData *objectData = [NSJSONSerialization dataWithJSONObject:object options:NSJSONWritingPrettyPrinted error:NULL];
    
    BOOL success = [_db executeUpdate:@"insert into http_cache (url,params,responseObject) values(?,?,?)",path,paramsData,objectData];
    
    if (success) NSLog(@"插入数据成功");
    
    else NSLog(@"插入数据失败");
}

+ (NSDictionary *)getDataWith:(NSString *)path parameters:(NSDictionary *)params {
    
    NSData *paramsData = [NSJSONSerialization dataWithJSONObject:params options:NSJSONWritingPrettyPrinted error:NULL];

    //降序排列，获取最新的记录
    FMResultSet *set = [_db executeQuery:@"select * from http_cache where url = ? and params = ? order by id desc",path,paramsData];
    
    NSDictionary *dict;
    
    //遍历查询到的记录
    while ([set next])
    {
        NSData *data = [set dataForColumn:@"responseObject"];
        dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:NULL];
    }
    
    return dict;
}

+ (void)BGETFromCache:(NSString *)url parameters:(id)params isFromCache:(BOOL)formCache success:(ResponseSuccess)success failure:(ResponseFailure)failure {
    
    //判断网络状态
    [ZHHttpManager currentReachability:^(AFNetworkReachabilityStatus status) {
       
        //没有网络从数据库中获取数据
        if (status == AFNetworkReachabilityStatusNotReachable)
        {
            
            NSDictionary *responseObject = [ZHHttpManager getDataWith:url parameters:params];
            
            if (responseObject)
            {
                success(nil,responseObject);
            }
            
        }//网络请求数据
        else
        {
            [ZHHttpManager BGET:url parameters:params success:^(ZHRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
                
                if (success) success(operation,responseObject);
                
                //将获取到的数据保存到数据库中
                [ZHHttpManager saveDataWith:url parameters:params responseObject:responseObject];
                
            } failure:^(ZHRequestOperation * _Nullable operation, NSError * _Nonnull error) {
                
                if (failure) failure(operation,error);
                
            }];
        }
        
    }];
    
}

+ (void)BPOSTFromCache:(NSString *)url parameters:(id)params isFromCache:(BOOL)formCache success:(ResponseSuccess)success failure:(ResponseFailure)failure {
    
}

//- (NSString *)fullURLPath:(NSString *)path parameters:(NSDictionary *)params {
//    
//    //定义一个变量
//    __block NSString *paramStr;
//    
//    [params enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
//        
//        NSString *keyStr = (NSString *)key;
//        NSString *valueStr;
//        NSString *paramStr;
//        
//        if ([obj isKindOfClass:[NSString class]])
//        {
//            valueStr = (NSString *)obj;
//        }
//        else if ([obj isKindOfClass:[NSNumber class]])
//        {
//            valueStr = [(NSNumber *)obj stringValue];
//        }
//        
//        paramStr = [NSString stringWithFormat:@"%@=%@",keyStr,valueStr];
//        
//        paramStr = [NSString stringWithFormat:@"%@&%@",];
//        
//    }];
//    
//    
//    return nil;
//}

@end
