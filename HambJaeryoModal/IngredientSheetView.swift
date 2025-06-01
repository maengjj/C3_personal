//
//  IngredientSheetView.swift
//  HambJaeryoModal
//
//  Created by coulson on 5/28/25.
//

import SwiftUI
import PhotosUI
import FirebaseAI
import SwiftData

struct IngredientSheetView: View {
    @Binding var showAddMenu: Bool
    @Binding var selectedMenuName: String
    
    @State private var isLoading = false
    @State private var navigateToResult = false
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var menuName: String = ""
    @State private var menuPrice: String = ""
    @State private var parsedIngredients: [IngredientInfo] = []
    
    
    @Environment(\.modelContext) private var context
    
    
    private var model: GenerativeModel?
    
    
    init(
        showAddMenu: Binding<Bool>,
        selectedMenuName: Binding<String>,
        firebaseService: FirebaseAI = FirebaseAI.firebaseAI()
    ) {
        _showAddMenu  = showAddMenu
        _selectedMenuName = selectedMenuName
        self.model = firebaseService.generativeModel(modelName: "gemini-2.0-flash-001")
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                
                List {
                    Section {
                        PhotosPicker(
                            selection: $selectedItem,
                            matching: .images,
                            photoLibrary: .shared()
                        ) {
                            if let image = selectedImage {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 32)
                                        .fill(Color.clear)
                                        .frame(height: 360)
                                        .overlay {
                                            Image(uiImage: image)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width:360, height: 360)
                                                .clipShape(RoundedRectangle(cornerRadius: 32))
                                        }
                                }
                            } else {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 32)
                                        .fill(Color.white)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    
                                    VStack {
                                        ZStack {
                                            Circle()
                                                .fill(Color.blue.opacity(0.1))
                                                .frame(width: 100, height: 100)
                                            Image(systemName: "photo.badge.plus")
                                                .font(.system(size: 20))
                                                .foregroundColor(.blue)
                                        }
                                        .padding(.bottom, 52)
                                        Text(
                                    """
                                    사진을 등록하면 자동으로
                                    재료 원가를 계산해 드릴게요
                                    """
                                        )
                                        .multilineTextAlignment(.center)
                                        .font(.title3)
                                        .fontWeight(.bold)
                                    }
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            }
                        }
                        .frame(width: 360, height: 360)
                        .onChange(of: selectedItem) { _, newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self),
                                   let uiImage = UIImage(data: data) {
                                    selectedImage = uiImage
                                }
                            }
                        }
                    }
                    .listRowBackground(Color.clear)
                    
                    
                    Section {
                        HStack {
                            Text("메뉴 이름")
                                .font(.body)
                                .fontWeight(.regular)
                            TextField("", text: $menuName)
                                .multilineTextAlignment(.trailing)
                                .foregroundStyle(.black)
                                .font(.body)
                                .fontWeight(.bold)
                        }
                        
                        HStack {
                            Text("메뉴 가격")
                                .font(.body)
                                .fontWeight(.regular)
                            TextField("", text: $menuPrice)
                                .multilineTextAlignment(.trailing)
                                .foregroundStyle(.black)
                                .font(.body)
                                .fontWeight(.bold)
                                .keyboardType(.numberPad)
                        }
                        .padding(.top, 16)
                        HStack{}
                    }
                    .listRowBackground(Color.clear)
                    
                    
                    Button {
                        isLoading = true
                        Task {
                            await analyzeIngredients()
                            isLoading = false
                        }
                    } label: {
                        Text("재료원가 계산하기")
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background((isLoading || selectedImage == nil || menuName.isEmpty || menuPrice.isEmpty) ? Color.gray : Color.blue)
                    .cornerRadius(10)
                    .disabled(isLoading || selectedImage == nil || menuName.isEmpty || menuPrice.isEmpty)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .padding(.top, 20)
                    
                }
            }
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color(.systemGray6))
            .navigationDestination(isPresented: $navigateToResult) {
                IngredientResultView(
                    selectedMenuName: $selectedMenuName,
                    showAddMenu: $showAddMenu,
                    menuName: menuName,
                    menuPrice: menuPrice,
                    image: selectedImage,
                    parsedIngredients: parsedIngredients
                )
            }
            .overlay {
                if isLoading {
                    ZStack {
                        Color.black.opacity(0.4).ignoresSafeArea()
                        VStack(spacing: 8) {
                            Text("재료를 분석 중이에요...")
                                .font(.body)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .padding(.bottom, 16)
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(2)
                        }
                        .padding()
                    }
                }
            }

        }
        .navigationTitle("재료원가계산")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    
    
    // MARK: - Gemini API 호출 및 파싱
    func analyzeIngredients() async {
        guard let selectedImage,
              //        guard let imageData = selectedImage.jpegData(compressionQuality: 0.7) else { return }
              let model else { return }
        
        let prompt = """
        음식 이름: \(menuName)
        음식 가격: \(menuPrice)원
        
        아래의 음식 이름과 사진을 참고하여, 이 음식에 사용된 재료 정보를 다음 JSON 형식으로 제공해줘:
        
        [
          {
            "name": "재료명",
            "amount": "사용량 및 그램단위 (예: 100g)",
            "unitPrice": 단위 원가 (숫자, 원 단위)
          },
          ...
        ]
        
        - 사용된 재료는 주재료 위주로 구성
        - 'unitPrice'는 'amount'의 단위 만큼만 사용했을 때 얼마인지 계산해줘.
        - 텍스트 설명 없이 JSON 배열만 출력
        """
        
        do {
                    let parts: [any PartsRepresentable] = [selectedImage]
                    var fullText = ""
                    for try await chunk in try model.generateContentStream(prompt, parts) {
                        if let text = chunk.text { fullText += text }
                    }
                    
                    // 백틱 제거 및 JSON 추출
                    let cleaned = fullText
                        .replacingOccurrences(of: "```json", with: "")
                        .replacingOccurrences(of: "```", with: "")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    guard
                        let first = cleaned.firstIndex(of: "["),
                        let last  = cleaned.lastIndex(of: "]"),
                        let data  = String(cleaned[first...last]).data(using: .utf8)
                    else { return }
                    
                    
                    let decoded = try JSONDecoder().decode([IngredientInfo].self, from: data)
                    // 1️⃣ – Main Thread에서 상태 갱신 및 저장 수행
                    await MainActor.run {
                        parsedIngredients = decoded
                        
                        // 3️⃣ – 저장이 끝나면 화면 전환
                        navigateToResult = true
                    }
                    
                } catch {
                    print("Gemini API 호출 실패: \(error)")
                }
                
            }
        }

#Preview {
    IngredientSheetViewPreview()
}

struct IngredientSheetViewPreview: View {
    @State var isPresented = true
    @State var showAddMenu = true
    @State var selectedMenuName = "함박스테이크"

    var body: some View {
        NavigationStack {
            IngredientSheetView(
                showAddMenu: $showAddMenu,
                selectedMenuName: $selectedMenuName
            )
        }
    }
}
