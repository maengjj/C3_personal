//
//  IngredientResultView.swift
//  HambJaeryoModal
//
//  Created by coulson on 5/29/25.
//

import SwiftUI

struct IngredientResultView: View {
    @Environment(\.dismiss) private var dismiss
    let dismissParentSheet: () -> Void
    let menuName: String
    let menuPrice: String
    let image: UIImage?
    let parsedIngredients: [IngredientInfo]

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
                ForEach(parsedIngredients) { ingredient in
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
    }
}


/*
struct IngredientResultView: View {
    @Environment(\.dismiss) private var dismiss
    let dismissParentSheet: () -> Void
    @State private var isEditing = false
    
    var body: some View {
        VStack {
            // 상단 바
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
            
            // 여기에 편집 여부에 따라 달라지는 내용 등 표시 가능
            VStack {
                if isEditing {
                    Text("편집 중입니다...")
                } else {
                    Text("계산된 재료 결과를 보여주는 영역")
                }
                
                Spacer()
                
                Button("저장하고 모두 닫기") {
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
            .padding()
        }
        .presentationDetents([.large])
    }
}
*/
