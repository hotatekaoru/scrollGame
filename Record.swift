//
//  Records.swift
//  scrollGame
//
//  Created by 保立馨 on 2016/06/12.
//  Copyright © 2016年 Kaoru Hotate. All rights reserved.
//

import Foundation
import RealmSwift

class Record: Object {
	dynamic var score: Int = 0
	dynamic var date = NSDate()
}
