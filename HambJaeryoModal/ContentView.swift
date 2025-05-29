//
//  ContentView.swift
//  HambJaeryoModal
//
//  Created by coulson on 5/28/25.
//

import SwiftUI

struct ContentView: View {
    @State private var showSheet = false
    
    var body: some View {
        Button("나의 메뉴 +") {
            showSheet = true
        }
        .sheet(isPresented: $showSheet) {
            IngredientSheetView(isPresented: $showSheet)
        }
    }
}


#Preview {
    ContentView()
}
