//
//  IngredientHistoryView.swift
//  HambJaeryoModal
//
//  Created by JiJooMaeng on 6/1/25.
//


//
//  IngredientHistoryView.swift
//  HambJaeryoModal
//
//  Created by coulson on 5/29/25.
//
import SwiftUI
import SwiftData

struct IngredientHistoryView: View {
    @Query(sort: \IngredientEntity.createdAt, order: .reverse)
    private var items: [IngredientEntity]
    var body: some View {
        List(items) { e in
            VStack(alignment: .leading) {
                Text(e.menuName).font(.headline)
                Text("\(e.name) • \(e.amount) • \(e.unitPrice)원")
                    .font(.subheadline).foregroundColor(.secondary)
            }
        }.navigationTitle("저장된 재료")
    }
}

#Preview {
    NavigationStack {
        IngredientHistoryView()
    }
}

