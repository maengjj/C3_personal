//
//  Untitled.swift
//  HambJaeryoModal
//
//  Created by coulson on 5/28/25.
//

import SwiftUI
import PhotosUI
import FirebaseAI
import SwiftData

struct IngredientSheetView: View {
    @Binding var isPresented: Bool
    @State private var navigateToResult = false
    
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var menuName: String = ""
    @State private var menuPrice: String = ""
    
    @Environment(\.modelContext) private var modelContext
    
    private var model: GenerativeModel?
    
    init(isPresented: Binding<Bool>, firebaseService: FirebaseAI = FirebaseAI.firebaseAI()) {
        self._isPresented = isPresented               // Binding 초기화
        self.model = firebaseService.generativeModel(modelName: "gemini-2.0-flash-001")
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
//                Color(.systemGray6).ignoresSafeArea()
                
                List {
                    Section {
                        PhotosPicker(
                            selection: $selectedItem,
                            matching: .images,
                            photoLibrary: .shared()
                        ) {
                            if let image = selectedImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .cornerRadius(12)
                                    .padding(.horizontal, 10)
                            } else {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 32)
                                        .fill(Color.white)
                                    Text(
                                        """
                                          사진을 등록하면 자동으로
                                        재료 원가를 계산해 드릴게요
                                        """
                                    )
                                    .font(.title3)
                                    .fontWeight(.bold)
                                }
                            }
                        }
                        .frame(height: 360)
                        .onChange(of: selectedItem) { newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self),
                                   let uiImage = UIImage(data: data) {
                                    selectedImage = uiImage
                                }
                            }
                        }
                    }
                    
                    Section {
                        HStack {
                            Text("메뉴 이름")
                            Spacer()
                            TextField("함박스테이크", text: $menuName)
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(.gray)
                        }
                        HStack {
                            Text("메뉴 가격")
                            Spacer()
                            TextField("14,900원", text: $menuPrice)
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Section {
                        Button("재료원가 계산하기") {
                            Task {
                                await analyzeIngredients()
                            }
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .background(Color(.systemGray6))
                .navigationDestination(isPresented: $navigateToResult) {
                    IngredientResultView(
                        dismissParentSheet: {
                            isPresented = false
                        },
                        menuName: menuName,
                        menuPrice: menuPrice,
                        image: selectedImage
                    )
                }
            }
        }
        .navigationTitle("재료원가계산")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Gemini API 호출 및 파싱
    func analyzeIngredients() async {
        guard let selectedImage else { return }
        guard let imageData = selectedImage.jpegData(compressionQuality: 0.7) else { return }
        guard let model else { return }
        
        let prompt = """
        음식 이름: \(menuName)
        음식 가격: \(menuPrice)원
        
        아래의 음식 이름과 사진을 참고하여, 이 음식에 사용된 재료 정보를 다음 JSON 형식으로 제공해줘:
        
        [
          {
            "name": "재료명",
            "amount": "사용량 및 단위 (예: 2큰술, 100g)",
            "unitPrice": 단위 원가 (숫자, 원 단위)
          },
          ...
        ]
        
        - 사용된 재료는 주재료 위주로 구성
        - 재료 수는 5~10개 정도로 제한
        - 'unitPrice'는 예측된 단가로 숫자만 제공
        - 텍스트 설명 없이 JSON 배열만 출력
        - 평균적으로 내가 너에게 준 음식이 구성되는 각 재료와 단위별 재료비의 원가를 알려고 해. 그리고 가능한한 kamis.or.kr 사이트의 기준으로 식재료 단위를 일치시켜서 표를 보여줘.
        """
        
        do {
            let parts: [any PartsRepresentable] = [selectedImage]
            var fullText = ""
            for try await content in try model.generateContentStream(prompt, parts) {
                if let line = content.text { fullText += line }
            }
            
            // 백틱 제거 및 JSON 추출
            let cleaned = fullText
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            let jsonString: String
            if let first = cleaned.firstIndex(of: "["), let last = cleaned.lastIndex(of: "]") {
                jsonString = String(cleaned[first...last])
            } else {
                jsonString = cleaned
            }
            
            if let data = jsonString.data(using: .utf8) {
                let decoded = try JSONDecoder().decode([TemporaryIngredient].self, from: data)
                
                let fetchDescriptor = FetchDescriptor<IngredientEntity>(
                    predicate: #Predicate { $0.menuName == menuName }
                )
                if let existing = try? modelContext.fetch(fetchDescriptor) {
                    for item in existing {
                        modelContext.delete(item)
                    }
                }
                
                for item in decoded {
                    let entity = IngredientEntity(
                        name: item.name,
                        amount: item.amount,
                        unitPrice: item.unitPrice,
                        menuName: menuName,
                        menuPrice: menuPrice,
                        image: imageData
                    )
                    modelContext.insert(entity)
                }
                try? modelContext.save()
                navigateToResult = true
            }
        } catch {
            print("Gemini API 호출 실패: \(error)")
        }
        
    }
    
}


private struct TemporaryIngredient: Decodable {
    let name: String
    let amount: String
    let unitPrice: Int
}

#Preview {
    NavigationStack {
        IngredientSheetView(isPresented: .constant(true))
    }
}
