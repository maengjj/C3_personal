//
//  Untitled.swift
//  HambJaeryoModal
//
//  Created by coulson on 5/29/25.
//

import SwiftUI
import SwiftData

@Model
class IngredientEntity {
    var id: UUID = UUID()
    var name: String
    var amount: String
    var unitPrice: Int
    var menuName: String
    var menuPrice: String

    init(name: String, amount: String, unitPrice: Int, menuName: String, menuPrice: String) {
        self.name = name
        self.amount = amount
        self.unitPrice = unitPrice
        self.menuName = menuName
        self.menuPrice = menuPrice
    }
}
