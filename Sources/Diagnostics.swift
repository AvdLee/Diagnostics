//
//  Diagnostics.swift
//  Diagnostics
//
//  Created by Antoine van der Lee on 02/12/2019.
//  Copyright © 2019 Antoine van der Lee. All rights reserved.
//

import Foundation

/// Defines supported `Diagnostics` to generate a report from.
public protocol Diagnostics: HTMLGenerating { }
extension Dictionary: Diagnostics where Key == String, Value == String { }
extension KeyValuePairs: Diagnostics where Key == String, Value == String { }
extension String: Diagnostics { }
extension DirectoryTreeNode: Diagnostics { }
