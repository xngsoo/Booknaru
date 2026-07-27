//
//  DSFont.swift
//  DesignSystem
//
//  Created by SEUNGSOO HAN on 7/27/26.
//  Copyright © 2026 xngsoo. All rights reserved.
//

import SwiftUI

/// 타이포 토큰. Dynamic Type에 반응하도록 시스템 텍스트 스타일 기반으로 정의한다.
public enum DSFont {
    public static let detailTitle = Font.title3.weight(.bold)
    public static let sectionTitle = Font.headline
    public static let bookTitle = Font.headline
    public static let author = Font.subheadline
    public static let body = Font.callout
    public static let meta = Font.footnote
    public static let caption = Font.caption
    public static let badge = Font.caption.weight(.bold)
}
