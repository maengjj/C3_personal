//
//  ContentView.swift
//  HambJaeryoModal
//
//  Created by coulson on 5/28/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var navigateToIngredientSheet = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    HStack {
                        Text("나의 메뉴")
                            .font(.title)
                            .fontWeight(.bold)
                        Spacer()
                        Button {
                            navigateToIngredientSheet = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.title)
                                .fontWeight(.bold)
                        }
                    }
                    Spacer()
                    List {
                        let items = (try? modelContext.fetch(FetchDescriptor<IngredientEntity>())) ?? []
                        ForEach(items, id: \.self) { item in
                            if let data = item.image,
                               let uiImage = UIImage(data: data) {
                                Section {
                                    NavigationLink {
                                        // 연결지점
                                    } label: {
                                        HStack {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .scaledToFit()
                                                .frame(height: 120)
                                                .frame(width: 60)
                                                .padding(.vertical, 3)
                                                .padding(.horizontal, 15)
                                                .background(Color(UIColor.systemGray5))
                                                .cornerRadius(12)
                                            VStack(alignment: .leading) {
                                                Text(item.menuName)
                                                    .font(.system(size: 18, weight: .bold))
                                                Text("가격: \(item.menuPrice)")
                                                    .font(.system(size: 12))
                                                    .foregroundStyle(.gray)
                                                    .lineLimit(3)
                                            }
                                        }
                                    }
                                }
                                .listSectionSeparator(.hidden, edges: [.top, .bottom])
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .background(Color.white)
                    
                }
                .padding(17)
                .navigationTitle("메뉴관리")
                .navigationBarTitleDisplayMode(.inline)
//                .toolbar {
//                    ToolbarItem(placement: .navigationBarTrailing) {
//                        Button {
//                            navigateToIngredientSheet = true
//                        } label: {
//                            Image(systemName: "plus")
//                                .font(.title2)
//                        }
//                    }
//                }
                .navigationDestination(isPresented: $navigateToIngredientSheet) {
                    IngredientSheetView(isPresented: .constant(false))
                }
            }
        }
    }
}


#Preview {
    NavigationStack {
        ContentView()
    }
}
