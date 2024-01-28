//
//  ContentView.swift
//  face-book
//
//  Created by Fraser Lee on 2024-01-27.
//

import SwiftUI
import SwiftData

struct ImageViewWrapper: UIViewRepresentable {
    let image: UIImage?

    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        vc.capturedImage = imageView
        return imageView
    }

    func updateUIView(_ uiView: UIImageView, context: Context) {
        uiView.image = image
    }
}


struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        // rounded rect taking up the top half of the screen with padding
        GeometryReader{ geo in
            VStack(spacing:10){
                HostedViewController()
                    .frame(height: geo.size.height * (1/2))
                    .cornerRadius(25.0)

            
                GeometryReader{ geo1 in
                    VStack (alignment: .leading) {
                        HStack (alignment: .top){
                            Button (action: toggleCam) {
                                Image(systemName: "camera.rotate.fill")
                                    .frame(width: 44, height: 44)
                                    .foregroundColor(.white)
                                    .background(.gray)
                                    .cornerRadius(13)
                                    .imageScale(.medium)
                            }
                        }
                        
                        Text("hello world.")
                            .font(.system(size: 25, weight: .regular, design: .rounded))
                            .frame(width: geo.size.width)
                        
                        ImageViewWrapper(image: UIImage(named: "my_image"))
                        
                    }.frame(width: geo.size.width)
                }
                .frame(height: geo.size.height * (1/2))
            }
        }.padding(.horizontal)
    }

    private func toggleCam() {
//        vc.setupVideoInput()
        vc.capturePhoto()
//
    }
}

#Preview {
    ContentView()
}
