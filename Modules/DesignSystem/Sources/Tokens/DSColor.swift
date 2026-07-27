//
//  DSColor.swift
//  DesignSystem
//
//  Created by SEUNGSOO HAN on 7/27/26.
//  Copyright © 2026 xngsoo. All rights reserved.
//

import SwiftUI

/// 의미 기반 색 토큰. 뷰는 .green/.orange 같은 원색이 아니라 여기 이름으로만 접근한다.
/// 시스템 semantic 색을 기반으로 해 라이트/다크 모드에 자동 대응한다.
public enum DSColor {
    /// 책나루 브랜드 액센트 (딥 틸)
    public static let accent = Color(red: 0.11, green: 0.53, blue: 0.53)
    /// 대출 가능
    public static let loanable = Color.green
    /// 대출 중 / 좌표 없음 등 비활성
    public static let unavailable = Color.secondary
    /// 휴관일 등 주의 강조
    public static let warning = Color.orange
    /// 카드/셀 배경
    public static let card = Color(.secondarySystemBackground)
    /// 보조 텍스트
    public static let secondaryText = Color.secondary
}
