//
//  ContentView.swift
//  face-book
//
//  Created by Fraser Lee on 2024-01-27.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        // rounded rect taking up the top half of the screen with padding
        GeometryReader{ geo in
            VStack{
                HostedViewController()
                    .frame(height: geo.size.height * (1/2))
                    .cornerRadius(25.0)
                    .padding()

            
                VStack{
                    Button (action: sayHi) {
                        Image(systemName: "camera.rotate.fill")
                            .frame(width: 52, height: 52)
                            .foregroundColor(.white)
                            .background(.gray)
                            .cornerRadius(10)
                            .imageScale(.medium)
                            
                    }
                    Text("hello world.")
                        .font(.system(size: 25, weight: .regular, design: .rounded))
                }.frame(height: geo.size.height * (1/2))
            }
        }
    }

    private func sayHi() {
        print("hi")
    }
}

#Preview {
    ContentView()
}
