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

            
                GeometryReader{ geo1 in
                    VStack (alignment: .leading) {
                        HStack (alignment: .top){
                            Button (action: toggleCam) {
                                Image(systemName: "camera.rotate.fill")
                                    .frame(width: 52, height: 52)
                                    .foregroundColor(.white)
                                    .background(.gray)
                                    .cornerRadius(15)
                                    .imageScale(.large)
                                
                            }
                        }
                        
                        Text("hello world.")
                            .font(.system(size: 25, weight: .regular, design: .rounded))
                            .frame(width: geo.size.width)
                            
                    }.frame(width: geo.size.width)
                }
                .background(Color.red)
                .frame(height: geo.size.height * (1/2))
                .padding()

            }
        }
    }

    private func toggleCam() {
        vc.setupVideoInput()
    }
}

#Preview {
    ContentView()
}
