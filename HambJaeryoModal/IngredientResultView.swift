//
//  IngredientResultView.swift
//  HambJaeryoModal
//
//  Created by coulson on 5/29/25.
//

import SwiftUI
import SwiftData

struct IngredientResultView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let dismissParentSheet: () -> Void
    let menuName: String
    let menuPrice: String
    let image: UIImage?
    @Query var parsedIngredients: [IngredientEntity]

    @State private var isEditing = false

    var body: some View {
        VStack {
            HStack {
                Button("닫기") {
                    dismiss()
                }

                Spacer()

                Text("계산 결과")
                    .font(.title2)
                    .bold()

                Spacer()

                Button(isEditing ? "완료" : "편집") {
                    isEditing.toggle()
                }
            }
            .padding(.horizontal)
            .padding(.top)

            Divider()

            List {
                ForEach(parsedIngredients, id: \.id) { ingredient in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(ingredient.name)
                            .font(.headline)
                        Text("사용량: \(ingredient.amount) / 단가: \(ingredient.unitPrice)원")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }

            Button("저장하고 모두 닫기") {
                for ingredient in parsedIngredients {
                    modelContext.insert(ingredient)
                }

                do {
                    try modelContext.save()
                } catch {
                    print("Failed to save ingredients: \(error)")
                }

                dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now()) {
                    dismissParentSheet()
                }
            }
            .font(.headline)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(12)
            .padding()
        }
        .presentationDetents([.large])
        .navigationBarBackButtonHidden(true)
    }
}
