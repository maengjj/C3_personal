//
//  Untitled.swift
//  HambJaeryoModal
//
//  Created by coulson on 5/28/25.
//

import SwiftUI
import PhotosUI
import FirebaseAI

struct IngredientSheetView: View {
    @Binding var isPresented: Bool
    @State private var showResultSheet = false
    
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var menuName: String = ""
    @State private var menuPrice: String = ""
    
    @State private var parsedIngredients: [IngredientInfo] = []
    
//    let model = FirebaseAI.firebaseAI().generativeModel(modelName: "gemini-1.5-pro")
    
//    let model = FirebaseAI.firebaseAI().generativeModel(modelName: "gemini-2.0-flash-001")
    
    private var model: GenerativeModel?

    init(isPresented: Binding<Bool>, firebaseService: FirebaseAI = FirebaseAI.firebaseAI()) {
            self._isPresented = isPresented               // Binding 초기화
            self.model = firebaseService.generativeModel(modelName: "gemini-2.0-flash-001")
        }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("재료원가 계산")
                .font(.title)
                .padding(.top)
                .frame(maxWidth: .infinity, alignment: .center)
            
            PhotosPicker(
                selection: $selectedItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .cornerRadius(12)
                        .padding(.horizontal, 10)
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.1))
                            .frame(height: 200)
                        Text("이미지 선택")
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 10)
                }
            }
            .onChange(of: selectedItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        selectedImage = uiImage
                    }
                }
            }
            
            Group {
                Text("메뉴 이름")
                    .font(.headline)
                TextField("예: 된장찌개", text: $menuName)
                    .textFieldStyle(.roundedBorder)
                
                Text("메뉴 가격")
                    .font(.headline)
                TextField("예: 9000", text: $menuPrice)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
            }
            .padding(.horizontal, 10)
            
            Spacer()
            
            Button("재료원가 계산하기") {
                Task {
                    await analyzeIngredients()
                }
            }
            .font(.headline)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
        .sheet(isPresented: $showResultSheet) {
            IngredientResultView(
                dismissParentSheet: {
                    isPresented = false
                },
                menuName: menuName,
                menuPrice: menuPrice,
                image: selectedImage,
                parsedIngredients: parsedIngredients
            )
        }
        .presentationDetents([.large])
    }
    
    // MARK: - Gemini API 호출 및 파싱
    func analyzeIngredients() async {
        guard let selectedImage else { return }
        guard let imageData = selectedImage.jpegData(compressionQuality: 0.7) else { return }
        guard let model else { return }
        //
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
                        parsedIngredients = try JSONDecoder().decode([IngredientInfo].self, from: data)
                        showResultSheet = true
                    }
                } catch {
                    print("Gemini API 호출 실패: \(error)")
                }
        
    }
    
}

/*
 import SwiftUI
 
 struct IngredientSheetView: View {
 @Binding var isPresented: Bool
 @State private var showResultSheet = false
 
 var body: some View {
 VStack {
 Text("재료원가 계산")
 .font(.title)
 
 Spacer()
 
 Button("재료원가 계산하기") {
 showResultSheet = true
 }
 .padding()
 }
 .presentationDetents([.large])
 .sheet(isPresented: $showResultSheet) {
 IngredientResultView(dismissParentSheet: {
 isPresented = false
 })
 }
 }
 }
 */
