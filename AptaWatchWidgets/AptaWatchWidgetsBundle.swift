//
//  AptaWatchWidgetsBundle.swift
//  AptaWatchWidgets
//
//  Created by Gazi Shahi on 3/16/26.
//

import WidgetKit
import SwiftUI

@main
struct AptaWatchWidgetsBundle: WidgetBundle {
    var body: some Widget {
        AptaInlineComplication()
        AptaCircularComplication()
        AptaRectangularComplication()
        AptaCornerComplication()
    }
}
